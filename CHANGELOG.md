# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] — 2026-06-17

Fixes incomplete per-file summary coverage found on the same monorepo: the graph held all 27 services, but only 2 had summaries because `repo-dna` summarized only the files it sampled while deriving conventions.

### Fixed
- **Summaries are now graph-driven and complete.** `repo-dna` writes a brief `summaries/files/<path>.md` for **every** service and lib node in `architecture-graph.json` (plus high-risk/high-fan-in), instead of just sampled files. `repo-graph` now sets `summary_ref` on every service/lib/high-risk node as the worklist.
- **`refresh-memory` runs the graph before DNA** so the node list can drive summary coverage, and reports "summaries: N of M service/lib nodes."
- **`repo-dna` samples conventions across many services**, not one, to avoid single-service bias (the run had leaned ~16× on one service).

## [0.2.0] — 2026-06-17

Fixes a major gap found on first real-world use (a 28-service monorepo with 200+ PRs): the full refresh derived conventions + the architecture graph but **never mined review history**, so `review-memory.md`, `pr-index/`, and `MEMORY-STATUS.md` stayed as shipped seed data — which then made PR reviews generic and surfaced a phantom seed PR.

### Fixed
- **`refresh-memory` now backfills review history.** It runs `review-memory` (backfill) and `similar-pr` (bulk index) over merged PRs in addition to `repo-dna` + `repo-graph`, then purges any leftover seed/example entries that don't map to the real repo.
- **`MEMORY-STATUS.md` is now generated deterministically** by `scripts/gen-memory-status.sh` (counts, confidence distribution, freshness, real repo name from git) — it can no longer show template/seed values like a phantom PR #1421.
- **No more fictional seed data installed.** `bootstrap` now lays down empty skeletons; nothing fictional (`@aravind`, login/orders, PR #1421) is written into a real repo.

### Added
- **`review-memory` BACKFILL mode** — paginates merged PRs, prioritizes threads with discussion/requested-changes, batches extraction through the `memory-indexer` subagent, caps the first pass (~60–100 PRs) for cost.
- **`similar-pr` BACKFILL mode** — bulk-indexes recent merged PRs.
- **`pr-review` quality bar** — concrete senior-engineer comment examples, explicit grounding requirements, and graceful handling that ignores empty/seed memory instead of grounding in fake patterns.

## [0.1.0] — 2026-06-17

Initial release of **Memory-Grounded Review** — a persistent, version-controlled
memory + context layer that makes Claude Code PR reviews repository-specific,
cheaper, and consistent. No proprietary backend: the memory is files in the repo,
the engine is Claude Code primitives.

### Added
- **Plugin packaging** — installable Claude Code plugin (`.claude-plugin/plugin.json`) with a one-plugin marketplace (`marketplace.json`).
- **Engine skills (6)** — `repo-dna`, `repo-graph`, `review-memory`, `similar-pr`, `context-pack`, and the `pr-review` orchestrator.
- **Command skills (3)** — `bootstrap-memory`, `refresh-memory`, `update-memory`.
- **Memory store schema** under `.claude/memory/` (`repo-dna.md`, `review-memory.md`, `architecture-graph.json`, `pr-index/`, `summaries/`) with a schema-correct seed-example tree.
- **Subagents** — `security-deep-dive` (isolated high-risk pass) and `memory-indexer` (cheap-model scanning/indexing).
- **Hooks** — secret-read block (jq-optional, fail-safe; allows reviewing source), comment-approval gate (interactive asks, CI steps aside), optional post-merge nudge.
- **Token strategy** — prompt-cache-optimized context assembly (stable cached memory prefix + dynamic diff suffix), relevance selection, compression, and knowledge aging.
- **`CLAUDE.md` template** + `install-into-repo.sh` bootstrapper (local-first; idempotent, never clobbers).
- **Optional GitHub Actions CI (Loop B)** — `pr-review.yml` and `memory-update.yml`, installed only with `--with-ci`; fork-PR guard, bot-loop guard, committer identity for memory commits.
- **`MEMORY-STATUS.md`** generated freshness/health dashboard.
- **Reference docs** — `reference/memory-schema.md` and `reference/token-strategy.md`.

### Notes
- v1 scope is Claude Code only. Repository drift detection / standard-promotion (Layer 5), multi-persona reviews, a hosted dashboard, and non-Claude-Code agents are deferred to later phases.

[0.1.0]: https://github.com/shubhamb-crayon/memory-grounded-review/releases/tag/v0.1.0
