---
name: context-pack
description: Assemble the minimal, relevant, cache-ordered context for reviewing a specific PR or diff — selecting and compressing the repo summary, relevant repo-dna rules, relevant review-memory patterns, the impact subgraph + touched-file summaries, and the top-3 similar PRs into a stable cached prefix, with the diff placed last as the dynamic suffix. Use this before running a review to keep prompt size and cost low. Enforces the token strategy.
---

# context-pack — assemble cheap, cached review context

You are the cost engine. Per review, the only genuinely novel input is the diff; the repository memory barely changes between PRs, so you assemble it as a **stable, cacheable prefix** and append the diff as the dynamic suffix. **Read `${CLAUDE_PLUGIN_ROOT}/reference/token-strategy.md` first — it is the spec you enforce.**

You produce no file; you return an ordered context bundle for `pr-review` (or the CI prompt) to consume.

## Inputs
- The diff / changed file list for the PR (or branch).
- The risk class from `pr-review` (low / medium / high) — controls depth.
- The memory files under `.claude/memory/`.

## Procedure

1. **Scope the diff.** Include only changed files and hunks. Never the whole tree.

2. **Compute the impact set.** Changed files → nodes (via `architecture-graph.json`) → **changed nodes ∪ direct neighbors** (1 hop; 2 hops for `risk: high` nodes). Pull the `summaries/files/<path>.md` only for files in this set.

3. **Select — relevance, not everything.**
   - **repo-dna rules:** only those whose `tags`/`area` match the changed areas/languages, confidence ≥ 0.6. Prefer high-confidence.
   - **review-memory patterns:** only those whose `tags` match; skip Archived. ~5 max.
   - **similar PRs:** call `similar-pr` retrieve → top 3.

4. **Compress.** Use the pre-built summaries (repo-summary, per-file summaries) rather than raw files. If something lacks a summary and is needed, summarize it inline tersely.

5. **Order for caching (most-stable first):**
   ```
   [tools / system / CLAUDE.md non-negotiables]
   repo-summary.md
   selected repo-dna rules
   selected review-memory patterns
   impact subgraph + touched-file summaries
   top-3 similar PRs
   === CACHE BREAKPOINT (place here) ===
   the diff   (dynamic suffix, full price)
   ```
   Everything above the breakpoint is the bundle that should hit the cache on subsequent reviews. **Never interleave the diff into the prefix** — it invalidates the cache.

6. **Enforce the budget.** Target bundle ≈ **3,000 tokens**. If over, drop in order: extra similar PRs → low-confidence rules/patterns → neighbor summaries furthest from the change. Keep the breakpoint after whatever survives.

7. **TTL guidance.** For an active review session or a CI batch, signal that the 1-hour cache TTL should be used so the prefix stays warm across the window (the +100% write is paid once, amortized over many ~10% reads).

8. **Return** the ordered bundle plus a one-line manifest (counts + estimated bundle tokens) so the reviewer and `MEMORY-STATUS` can report cache efficiency.

## Replay (PR `synchronize`)
If a prior review of this PR exists, pack only the lines changed since then + any newly affected nodes; reuse prior findings for untouched code. The memory prefix is unchanged → cache hit; pay full price only on the small new delta.

## Guardrails
- Selection first, then caching: a small relevant payload beats a big cached one.
- Don't include Archived / sub-0.6 entries just to look thorough.
- No secrets in the bundle.
