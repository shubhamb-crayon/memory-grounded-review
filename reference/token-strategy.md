# Token strategy (the cost engine)

One principle: **cache the stable, send only the delta, and never send what isn't relevant.** Per review, the only genuinely novel input is the diff; the repository memory barely changes between PRs, so it must be cheap to reuse. The `context-pack` skill enforces everything here; `pr-review` consumes the result.

---

## 1. Prompt caching — the primary lever

Anthropic prompt caching reuses a stable prefix across requests at a fraction of the cost. Mechanics this design exploits:

- **Cache reads cost ~10% of base input price** (≈90% reduction on a hit). **Cache writes cost +25% over base input for the 5-minute TTL, or +100% for the 1-hour TTL.**
- Caching is **prefix-based**, processed in order **tools → system → messages**. Anything that changes mid-prefix invalidates everything after it.
- **Minimum cacheable block: 1,024 tokens.** Up to **4 cache breakpoints.** TTL **refreshes on each read.**
- Default TTL is 5 minutes; the 1-hour option is explicit and **also available on Amazon Bedrock** for current Claude models.

**Rules `context-pack` enforces:**

1. **Memory bundle in the stable prefix** — repo summary + relevant `repo-dna` rules + relevant `review-memory` patterns + impact subgraph + top-3 similar PRs — with a **cache breakpoint placed right after it**.
2. **Diff goes last**, as the dynamic suffix. Never interleave dynamic content into the prefix.
3. During an active review session or CI batch, use the **1-hour TTL** so the prefix stays warm across all PRs in that window — the +100% write is paid once and amortized over many ~10% reads.
4. **Knowledge aging keeps the prefix small and stable** → comfortably within block/breakpoint limits, changes rarely, high hit rate.

Ordering inside the prefix (most-stable first, so edits invalidate as little as possible):

```
[tools]
[system / CLAUDE.md non-negotiables]      ← changes almost never
repo-summary.md                            ← changes rarely
relevant repo-dna rules                    ← changes occasionally
relevant review-memory patterns            ← changes occasionally
impact subgraph + touched-file summaries   ← changes per PR-area
top-3 similar PRs                          ← changes per PR
=== CACHE BREAKPOINT ===
the diff                                    ← dynamic, full price
```

---

## 2. Selection — send only what's relevant

Caching makes reuse cheap; selection makes the payload small in the first place.

- **Diff-scoping:** only changed files and hunks, never the whole tree.
- **Graph-neighbor expansion:** include file summaries only for the **impact set** — changed nodes plus their direct neighbors from `architecture-graph.json` — not every file.
- **Pattern filtering:** include only `review-memory` patterns whose `tags` match the changed areas/languages.
- **Top-k similar PRs:** the 3 best matches from `pr-index/`, not the whole index.

---

## 3. Tiered summary budget

| Context piece | Approx. size | Cached? |
|---|---|---|
| Repo summary | ~500 tokens | Yes (prefix) |
| Impact subgraph (changed + neighbors) | ~300–800 tokens | Yes (prefix) |
| Relevant `repo-dna` rules | ~50–100 tokens each | Yes (prefix) |
| Relevant `review-memory` patterns | ~50 tokens each (~5) | Yes (prefix) |
| Per-file summaries (touched files only) | ~100 tokens each | Yes (prefix) |
| Top-3 similar PRs | ~100 tokens each | Yes (prefix) |
| **The diff** | variable (the real payload) | No (dynamic suffix) |

Target bundle size: **~3,000 tokens**. If the selected bundle exceeds budget, drop in this order: extra similar PRs → low-confidence rules/patterns → neighbor file summaries furthest from the change.

---

## 4. Review replay — don't re-pay on updates

On `synchronize` (a push to an open PR), re-review **only** the lines changed since the last review plus any newly affected graph nodes, and reuse prior findings for untouched code. Because the memory prefix is unchanged, this run is a **cache hit** — ~10% on the bundle, full price only on the small new delta.

---

## 5. Worked example (illustrative — actual numbers vary by repo, model, pricing)

- **Naive whole-repo review:** ~80,000 tokens of repo context + ~4,000-token diff ≈ **84,000 input tokens at full price**, every review.
- **Optimized, first review in a window (cache write):** ~3,000-token bundle written at +100% (1-hour TTL) ≈ ~6,000-token-equivalent, **paid once**, plus the ~4,000-token diff at full price.
- **Every subsequent review in the warm window (cache read):** ~3,000-token bundle read at 10% ≈ **~300 token-equivalent**, plus the ~4,000-token diff.

That clears the **≥70% prompt-size reduction** target on payload alone; on warm caches the *cost* reduction is far larger because the bulk of input bills at the read rate. Replay compounds it further.

---

## 6. How this maps to claude-code-action

In CI the action runs the full Claude Code runtime, so prompt caching applies automatically to the system prompt and tool definitions. To get the memory-bundle caching benefit:

- Keep `CLAUDE.md` + the assembled bundle stable across a workflow run.
- Prefer one review invocation that reads the bundle once, rather than many small tool calls that re-send context.
- For a CI batch (e.g. re-running across many PRs), the 1-hour TTL keeps the prefix warm across the batch window.
