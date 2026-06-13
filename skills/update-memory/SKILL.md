---
name: update-memory
description: Update repository memory from a just-merged pull request — mines the PR thread (review-memory), incrementally updates the architecture graph (repo-graph), indexes the PR for similar-PR recall (similar-pr), lightly refreshes affected conventions (repo-dna), and regenerates MEMORY-STATUS.md. Use as /repo-memory:update-memory or from the memory-update.yml CI workflow on merge. This is how memory stays fresh with zero human upkeep.
---

# update-memory — keep memory fresh on every merge

The per-merge entry point (the default in CI). It runs the *incremental* updates so memory compounds with every merged PR — cheaply.

## Inputs
- The merged PR number (CI provides it; interactively, ask or infer from the last merge).
- `git`/`gh` (or GitHub MCP) access to the PR thread and diff.

## Procedure (order matters — graph before index)
1. **Mine the review thread.** Run **`review-memory`** on the merged PR → update patterns + reviewer preferences (counts, confidence, aging) in `review-memory.md`.
2. **Incremental graph update.** Run **`repo-graph`** in incremental mode on the merged file set → add/update/remove only touched nodes/edges in `architecture-graph.json`.
3. **Index the PR.** Run **`similar-pr`** in index mode → append `pr-index/YYYY-MMDD-PR-<n>.md` (resolving nodes via the now-updated graph).
4. **Light DNA refresh.** Run **`repo-dna`** in light-refresh mode → re-confirm/adjust only rules touched by the merged files; refresh affected summaries; apply aging. (No full rebuild — that's `refresh-memory`.)
5. **Regenerate the dashboard.** Rewrite `MEMORY-STATUS.md` per `${CLAUDE_PLUGIN_ROOT}/templates/MEMORY-STATUS.md`: counts, confidence distribution, last update, graph size, recent PRs indexed.
6. **Commit back (CI).** In the `memory-update.yml` job (which has `contents: write`), commit the changed `.claude/memory/**` and `MEMORY-STATUS.md` to the repo with a clear message, e.g. `chore(memory): update from PR #<n>`. Interactively, leave staged for the human.

## Why this is cheap
Everything here is incremental and small. The expensive full re-derivation is reserved for `refresh-memory`. Keeping per-merge updates tiny is what keeps the cached review prefix stable (see `${CLAUDE_PLUGIN_ROOT}/reference/token-strategy.md`).

## Guardrails
- **Never trigger on the bot's own merges** — the workflow guards `github.actor != 'claude[bot]'`; respect it so memory doesn't learn from itself.
- Commit only memory/dashboard files; never application code from this skill.
- Never write secrets/PII into memory. Keep entries evidence-backed and confidence-honest.
