---
name: review-memory
description: Mine merged pull-request comment threads to extract recurring review patterns and individual reviewer preferences, with occurrence / accepted / rejected counts and confidence (plus knowledge aging), into .claude/memory/review-memory.md. Has two modes — INCREMENTAL (one merged PR, called by update-memory) and BACKFILL (many historical PRs, called by refresh-memory on first install). This is what stops reviews from re-litigating settled decisions and what makes them reflect how the team actually reviews.
---

# review-memory — mine how the team reviews

You turn PR discussion (which nobody re-reads) into durable, confidence-scored review knowledge. **Read the schema first:** `${CLAUDE_PLUGIN_ROOT}/reference/memory-schema.md` (the `review-memory.md` section). Records are **review patterns** and **reviewer preferences**, each classified `team-convention` | `reviewer-preference` | `temporary-trend`.

**Output:** `.claude/memory/review-memory.md`.

> If the file still contains the shipped **seed example** (header says "seed example", or ids `di-over-singleton` / `validate-at-boundary` / `pref-aravind-tests` / `legacy-dateutil`), treat it as empty and **overwrite** it — those are not this repo's patterns.

---

## Mode A — BACKFILL (first install / full refresh)

Goal: populate `review-memory.md` from the repo's *existing* review history. This is the step that makes a brand-new install actually know the team's standards.

1. **Enumerate candidate PRs.** Pull merged PRs newest-first:
   ```bash
   gh pr list --state merged --limit 200 \
     --json number,title,reviewDecision,comments,reviews,updatedAt
   ```
   (Paginate with `--search "is:merged sort:updated-desc"` for >200.)

2. **Prioritize — don't mine everything equally.** Reviewer standards live in PRs that had *discussion*, not rubber-stamps. Rank candidates by: had `CHANGES_REQUESTED`; review-comment count; threads later resolved (accepted). Take the top **~60–100** by signal on the first backfill (state the cap in your report; the rest get picked up incrementally on future merges). This keeps cost bounded on big repos.

3. **Extract in bulk via the cheap worker.** Route the per-PR thread fetch + raw extraction to the **`memory-indexer`** subagent (haiku) in batches, so the main context stays clean. For each PR it returns compact `{pattern, pr, outcome, reviewer, area-tags}` records. Per PR:
   ```bash
   gh pr view <n> --json title,reviews,comments,reviewThreads,files,author
   ```
   A blocking review whose change was then made = **accepted**; pushback the reviewer dropped = **rejected**.

4. **Consolidate into patterns.** Cluster the raw records into reusable rules of thumb (not verbatim quotes). Merge near-duplicates. For each, compute `occurrences`, `accepted`, `rejected`, and `confidence ≈ accepted/(accepted+rejected)` damped for low volume (a 1-of-1 is not 1.0). Tag with areas/languages so `context-pack` can filter (for this kind of repo: `python`, `lambda`, `pydantic`, `testing`, `bedrock`, `ci`, …). Classify each as team-convention / reviewer-preference / temporary-trend.

5. **Write** `review-memory.md` per the schema, ordered by `id`, with a real header line (counts + today's date). Overwrite any seed content.

---

## Mode B — INCREMENTAL (on merge, via update-memory)

1. Pull the one merged PR's thread (`gh pr view <n> --json reviews,comments,reviewThreads,author,files,title`).
2. Extract patterns; match to existing `id`s or create new ones.
3. Update counts (`occurrences`, `accepted`/`rejected`), recompute `confidence`, refresh `last_seen`.
4. Classify; record reviewer-specific items under "Reviewer preferences" naming the `@handle`.

---

## Always: knowledge aging
Decay confidence for patterns not seen within the aging window (~45 days). Move anything below the floor (~0.3) to `## Archived`, excluded from review context. Keeps the cached bundle small and stable.

## Guardrails
- **Record outcomes, not drama.** Summarize the rule of thumb; no long quotes, no blame.
- **No PII/secrets.** Reviewer handles are fine; personal data is not.
- Volume **and** accept-rate drive confidence — one loud thread shouldn't spike it.
- **Never fabricate.** If history is thin, write few patterns honestly rather than padding.
- Writes only the memory file; posts nothing to GitHub.
