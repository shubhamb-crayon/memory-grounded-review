---
name: refresh-memory
description: Re-derive a repository's memory on demand — full repo-dna pass (conventions + summaries), full repo-graph build, AND a full backfill of review history (review-memory mined from merged PR threads + similar-pr index of past PRs), then deterministically regenerate MEMORY-STATUS.md. Use as /memory-grounded-review:refresh-memory, on first install, or periodically to keep everything current.
---

# refresh-memory — full rebuild incl. review-history backfill

The on-demand, full-rebuild entry point. Unlike the per-merge `update-memory`, this **backfills from the whole history** — it must populate `review-memory.md` and `pr-index/` from existing merged PRs, not just conventions + graph. On an existing repo with hundreds of PRs, skipping that is the difference between memory-grounded reviews and generic ones.

## Procedure

1. **Preconditions.** Confirm `.claude/memory/` exists (else suggest `/memory-grounded-review:bootstrap-memory`). Check GitHub access: `gh auth status` (or GitHub MCP). If there's no GitHub access, do steps 2–3 and warn that review-history backfill (steps 4–5) was skipped.

2. **Architecture graph (full) — FIRST.** Run the **`repo-graph`** skill in full-build mode → rebuild `architecture-graph.json` with stable ordering, with a `summary_ref` on every service/lib/high-risk node. Build it before DNA so its node list can drive full summary coverage.

3. **Repository DNA (full).** Run the **`repo-dna`** skill in full-build mode → `repo-dna.md` (conventions sampled across many services, not one), `summaries/repo-summary.md`, and a per-node `summaries/files/<path>.md` for **every** service and lib node in the graph (not just sampled files). Apply aging.

4. **Review history backfill (this is the step that was missing).** Run the **`review-memory`** skill in **backfill mode** over merged PRs (see that skill). Mine reviewer comments / requested-changes across history into real `review-memory.md` patterns + reviewer preferences. This is what makes reviews reflect *how this team actually reviews*.

5. **Similar-PR index backfill.** Run the **`similar-pr`** skill in **backfill mode** to index the most recent / most-substantive merged PRs into `pr-index/`.

6. **Purge any seed/example leftovers.** Bootstrap may have dropped illustrative examples that don't belong in a real repo. Remove them so nothing phantom survives:
   - Delete `pr-index/*` entries that don't correspond to a real PR in this repo (e.g. the example `2026-0612-PR-1421.md`).
   - Delete `summaries/files/**` whose mirrored source path doesn't exist in the repo (e.g. seed `src/api/login.md`, `src/services/auth.md`).
   - If `review-memory.md` still contains the seed header "This is a seed example" or seed ids (`di-over-singleton`, `validate-at-boundary`, `pref-aravind-tests`, `legacy-dateutil`) and they weren't re-derived from this repo's PRs, replace the file with the backfilled content from step 4.

7. **Regenerate the dashboard deterministically.** Run:
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/gen-memory-status.sh" "$(git rev-parse --show-toplevel)"
   ```
   This computes `MEMORY-STATUS.md` from the actual files (counts, confidence distribution, freshness, real repo name) — never from a template. Do **not** hand-write the dashboard.

8. **Report & stage.** Summarize: conventions (added/aged/archived), graph node/edge delta, **per-node summaries written (N of M service/lib nodes — should be all of them)**, **review patterns + reviewer prefs mined**, **PRs indexed**, seeds purged. Leave everything staged for the human to review and commit — memory changes are PRs.

## Scope note
This is the **heavy** path (minutes on a large repo, and review backfill makes many `gh` calls). The per-merge path is `update-memory`. Run a full refresh on first install and occasionally (e.g. monthly / on a scheduled job), not on every merge.

## Guardrails
- Read-only against GitHub for mining; writes only local memory files + the dashboard.
- Never read secrets. Keep files small and diff-friendly.
- Never fabricate review patterns to look thorough — only record what the PR threads actually show (see `review-memory` honesty rules).
