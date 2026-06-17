---
name: refresh-memory
description: Re-derive a repository's memory on demand — runs a full repo-dna pass (conventions + summaries) and a full repo-graph build (architecture-graph.json), then regenerates the MEMORY-STATUS.md dashboard. Use as /memory-grounded-review:refresh-memory, on first install, or periodically (e.g. weekly in CI) to keep conventions and the architecture map current.
---

# refresh-memory — rebuild conventions + graph on demand

The on-demand, full-rebuild entry point. Use it on first install and whenever you want memory re-derived from the current state of the repo (vs. the incremental update that runs on each merge).

## Procedure
1. **Preconditions.** Confirm `.claude/memory/` exists. If not, suggest `/memory-grounded-review:bootstrap-memory` first.
2. **Repository DNA (full).** Run the **`repo-dna`** skill in full-build mode → refreshes `repo-dna.md`, `summaries/repo-summary.md`, and `summaries/files/<path>.md`. Apply knowledge aging.
3. **Architecture graph (full).** Run the **`repo-graph`** skill in full-build mode → rebuilds `architecture-graph.json` with stable ordering.
4. **Dashboard.** Regenerate `MEMORY-STATUS.md` (rule/pattern counts, confidence distribution, last-refreshed, graph size). Follow the layout in `${CLAUDE_PLUGIN_ROOT}/templates/MEMORY-STATUS.md`.
5. **Report & stage.** Summarize what changed (rules added/aged/archived, graph node/edge delta). Leave edits staged for the human to review and commit — memory changes are PRs. In CI (weekly refresh) the workflow commits them.

## Scope note
This is the **heavy** path. The per-merge path is `update-memory` (mines the just-merged PR, incremental graph update, indexes the PR). Don't run a full refresh on every merge — it defeats the caching/cost strategy.

## Guardrails
- Read-only against GitHub; writes only local memory files.
- Never read secrets. Keep files small and diff-friendly.
