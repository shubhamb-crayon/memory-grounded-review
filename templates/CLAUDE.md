<!--
  Repository Memory — CLAUDE.md template.
  bootstrap-memory copies this into your repo root (merging into any existing CLAUDE.md).
  Everything between the markers below is owned by Repository Memory; edit outside the markers freely.
-->

# Project memory

<!-- BEGIN repo-memory -->
## Repository Memory

This repo uses **Repository Memory**. Persistent, version-controlled knowledge lives under `.claude/memory/`. Read it before reviewing or making non-trivial changes, and keep it current.

**Memory files (read these):**
- `.claude/memory/repo-dna.md` — conventions & rules this repo actually follows, each with a confidence score and evidence. Apply rules with confidence ≥ 0.85 firmly; treat 0.6–0.85 as suggestions; mention < 0.6 only.
- `.claude/memory/review-memory.md` — recurring review patterns and individual reviewer preferences. Don't re-litigate settled decisions recorded here.
- `.claude/memory/architecture-graph.json` — lightweight dependency graph. Use it to compute the **impact set** (changed nodes + direct neighbors) for blast-radius analysis.
- `.claude/memory/pr-index/` — compact summaries of past PRs. Recall the most similar ones when reviewing.
- `.claude/memory/summaries/` — compressed repo + per-file overviews used to build cheap, cached context.
- `MEMORY-STATUS.md` — generated freshness/health dashboard.

**Commands:**
- `/repo-memory:pr-review` — review the current branch/PR, grounded in memory, with risk-based depth.
- `/repo-memory:refresh-memory` — re-derive conventions and the architecture graph on demand.
- `/repo-memory:update-memory` — mine the merged PR, update memory, regenerate the dashboard.

**Non-negotiables (always):**
1. **Never post a review comment without approval.** In interactive use, surface findings and wait for confirmation before posting to GitHub. In CI the workflow handles posting.
2. **Never read or echo secrets.** Do not open `.env`, `.env.*`, `*.pem`, `id_rsa`, `secrets/**`, or credential files. Do not copy secrets or PII into memory files.
3. **Ground every finding in memory or evidence.** Prefer "this violates `repo-dna` rule `<id>`" or a cited line over generic best-practice advice.
4. **Memory changes are PRs.** Any edit to a memory file must be reviewable; never silently rewrite a standard — adjust confidence and cite new evidence.
5. **Respect the token strategy.** Pull in only the relevant, compressed slice of memory (see the `context-pack` skill). Don't load the whole tree.
<!-- END repo-memory -->

<!-- Add your own project notes below this line. -->
