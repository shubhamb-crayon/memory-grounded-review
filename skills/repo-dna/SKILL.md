---
name: repo-dna
description: Derive or refresh a repository's coding conventions and rules — the "Repository DNA" — from its code, merged PRs, docs, and lint/CI config, writing them with confidence scores and evidence to .claude/memory/repo-dna.md. Use on first install, on /memory-grounded-review:refresh-memory, when asked to learn or update repo conventions/standards, or periodically in CI. Also (re)generates the compressed repo + per-file summaries used for cached review context.
---

# repo-dna — build & refresh Repository DNA

You extract the conventions this repo **actually follows** (not textbook best practice) and record them as small, evidence-backed, confidence-scored rules. You also (re)generate the compressed summaries that feed cheap, cached review context.

**Outputs:**
- `.claude/memory/repo-dna.md` (rules)
- `.claude/memory/summaries/repo-summary.md` (~500 tokens)
- `.claude/memory/summaries/files/<path>.md` (~100 tokens each, important files only)

**First, read the schema** so your output is valid and diff-friendly: `${CLAUDE_PLUGIN_ROOT}/reference/memory-schema.md`. For the summary-size rules: `${CLAUDE_PLUGIN_ROOT}/reference/token-strategy.md`.

## When to run which mode
- **Full build** — first install, `/memory-grounded-review:refresh-memory`, or weekly CI. Derive the full rule set + summaries.
- **Light refresh** — after a merge (called by `update-memory`). Only re-confirm/adjust rules touched by the merged files; apply aging; don't rebuild everything.

## Procedure

1. **Gather signal (cheap → rich).** Prefer routing the bulk scan to the `memory-indexer` subagent to keep this context clean.
   - **Config is ground truth.** Read linter/formatter/type configs and CI: `.eslintrc*`, `biome.json`, `.prettierrc*`, `tsconfig.json`, `pyproject.toml`, `.editorconfig`, `.github/workflows/*`, `CODEOWNERS`, `CONTRIBUTING.md`, `ARCHITECTURE.md`, existing `CLAUDE.md`. Rules encoded here get **high confidence** — they are enforced.
   - **Code patterns.** Sample representative files per area (`src/api`, `src/services`, etc.). Look for repeated shapes: error handling, response envelopes, naming, layering, logging, test placement, import style.
   - **Merged PR signal.** `gh pr list --state merged --limit 50 --json number,title,files,reviews` (or GitHub MCP). Conventions that reviewers *enforced* (requested-changes that were then fixed) are strong evidence.
   - **Git history.** `git log` for recurring refactors ("convert X to Y") signal a direction of travel.

2. **Synthesize rules.** For each candidate convention, write one block per the schema with: `id` (kebab-case, stable), `confidence`, `status`, `area`, `tags`, `evidence` (file:line and/or PR #), `rule`, a short `example`, optional `rationale`, and `last_seen` (today).
   - Confidence calibration: enforced-by-CI/lint ≈ 0.9+; consistent across many files + reviewer-enforced ≈ 0.8–0.9; observed but inconsistent ≈ 0.5–0.7; single instance ≈ < 0.5 (mark as candidate).
   - **Be honest.** A rule with thin evidence gets low confidence, not high. Never invent evidence.

3. **Apply knowledge aging** (light refresh and full build):
   - If a previously-recorded rule is re-observed, refresh `last_seen` and nudge confidence up (cap 0.98).
   - If not re-observed for the aging window (default ~45 days), set `status: aging` and decay confidence; below ~0.3 move it under a `## Archived`/deprecated note. This keeps the cached bundle small and stable.

4. **(Re)generate summaries.**
   - `repo-summary.md`: purpose, stack, top-level layout, critical/high-risk areas, conventions-in-force, how-the-team-reviews pointer. Keep ~500 tokens.
   - `summaries/files/<path>.md`: only for **important** files (high-risk or high fan-in per `architecture-graph.json`). ~100 tokens each: role, risk, touchpoints, common pitfalls.

5. **Write atomically & stay diff-friendly.** Order rules by `id` within each area heading so PR diffs are readable. Update the header counts/date line. Preserve human-added prose outside generated blocks where present.

6. **Hand back to the caller.** Report: rules added / updated / aged / archived, and which summaries changed. In CI the `memory-update` workflow commits the result; interactively, leave the edits staged for the human to review and commit.

## Guardrails
- Never read or transcribe secrets (`.env*`, keys, `secrets/**`). The plugin's hooks enforce this; respect it anyway.
- Don't bloat: this file should stay readable. If two rules overlap, merge them.
- Don't post anything to GitHub from this skill — it only writes local memory files.
