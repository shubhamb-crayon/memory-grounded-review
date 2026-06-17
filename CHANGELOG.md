# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
