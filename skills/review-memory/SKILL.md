---
name: review-memory
description: Mine merged pull-request comment threads to extract recurring review patterns and individual reviewer preferences, then update their occurrence / accepted / rejected counts and confidence (with knowledge aging) in .claude/memory/review-memory.md. Use on merge (called by /repo-memory:update-memory) or when asked to learn how the team reviews. This is what stops the reviewer from re-litigating settled decisions.
---

# review-memory — mine how the team reviews

You turn PR discussion (which nobody re-reads) into durable, confidence-scored review knowledge so reviews stop repeating the same comments and stop re-opening settled debates.

**Output:** `.claude/memory/review-memory.md`. **Read the schema first:** `${CLAUDE_PLUGIN_ROOT}/reference/memory-schema.md` (the `review-memory.md` section). Two record types: **review patterns** and **reviewer preferences**, each classified `team-convention` | `reviewer-preference` | `temporary-trend`.

## Procedure

1. **Pull the thread(s).** For the merged PR (or a batch on full refresh):
   - `gh pr view <n> --json reviews,comments,reviewThreads,author,files,title` (or GitHub MCP equivalent).
   - Capture: who said what, whether it was a blocking review (requested changes), and whether the author then changed the code (resolved) → that's an **accepted** outcome. A pushback that the reviewer dropped → **rejected**.

2. **Extract patterns.** Normalize each substantive review comment into a reusable rule of thumb (not a verbatim quote). Examples: "asks for input validation at the boundary", "prefers DI over singletons", "wants tests in the same PR". Tag with areas/languages (`[security, api]`, `[testing]`, …) so `context-pack` can filter by relevance.

3. **Update counts & confidence.** For each pattern:
   - Match to an existing entry by `id` if present; otherwise create one.
   - Increment `occurrences`; increment `accepted` or `rejected` based on outcome.
   - Recompute `confidence` from the accept rate and volume, e.g. roughly `accepted / (accepted + rejected)` damped by low counts (a 1-of-1 is not 1.0 confidence). Cap at 0.98.
   - Refresh `last_seen` to the merge date.

4. **Classify.** 
   - **team-convention** — raised by multiple reviewers and broadly accepted.
   - **reviewer-preference** — consistently from one person; record under "Reviewer preferences" and name them (`@handle`). Useful so the author can pre-empt that reviewer.
   - **temporary-trend** — recent, not yet broadly established; watch it.

5. **Apply knowledge aging.** Decay confidence for patterns not seen within the aging window (default ~45 days). Move anything below the floor (~0.3) to the `## Archived` section and exclude it from review context. This keeps the cached bundle small and stable.

6. **Write diff-friendly.** One block per pattern, ordered by `id` within each section; update the header summary line (counts, last-mined date). Prefer updating an existing entry over appending a near-duplicate; merge overlaps.

7. **Hand back.** Report patterns created / reinforced / contradicted / aged. In CI, `update-memory` commits; interactively, leave staged for human review.

## Guardrails
- **Record outcomes, not drama.** Summarize the rule of thumb; don't paste long quotes or attribute blame.
- **No PII / secrets** in the file. Reviewer handles are fine; personal data is not.
- Don't let one loud thread spike confidence — volume and accept-rate together drive it.
- This skill writes only the memory file; it posts nothing to GitHub.
