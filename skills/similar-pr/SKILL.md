---
name: similar-pr
description: Index merged pull requests as compact markdown files under .claude/memory/pr-index/, and at review time retrieve the top-3 most similar prior PRs (by tag / node / file overlap, via reasoning — no embeddings or vector DB). Use on merge to append the just-merged PR, and during review to recall how similar past changes were handled, what broke, and what reviewers required.
---

# similar-pr — index & recall past PRs

Reuse history. Most changes rhyme with something already merged. You keep a compact, tagged index of past PRs and surface the closest matches when a new one is under review.

**Store:** `.claude/memory/pr-index/` — one file per PR, named `YYYY-MMDD-PR-<number>.md`. **Read the schema first:** `${CLAUDE_PLUGIN_ROOT}/reference/memory-schema.md` (the `pr-index/` section defines the YAML frontmatter + body).

## Mode A — Index (on merge)
1. Collect the merged PR's facts: number, title, merge date, author, changed `files`, affected `nodes` (resolve via `architecture-graph.json`), `tags` (areas/languages/themes), `outcome`, and any `follow_up` (incident / revert / hotfix link if known).
2. Write the file with that frontmatter, plus a short body: **Intent**, **Key review outcomes** (what reviewers required — cross-reference `review-memory` / `repo-dna` ids), and **Lessons / gotchas** (esp. high-risk touchpoints).
3. Keep it compact (~100–150 tokens of body). Stable field order so diffs are clean.

## Mode B — Retrieve (at review time)
1. Compute the candidate PR's signature: changed files → nodes (via the graph) → tags.
2. Score each indexed PR by overlap, roughly weighted: **shared nodes > shared files > shared tags**, with a small recency bonus and a boost for any PR with a `follow_up` (incident/revert/hotfix) touching the same area — those are the cautionary tales worth surfacing.
3. Return the **top 3** as compact context for `context-pack`: title, why-similar (the overlap), and the one-line lesson. Don't dump whole files.

> Retrieval is just you reading `pr-index/` and reasoning about similarity. **No embeddings / vector store in v1.** If measured recall is ever insufficient, prefer a managed embedding service over building one (see the PRD risks) — but only then.

## Guardrails
- Top-k = 3 by default; never load the whole index into a review.
- If `pr-index/` is empty (fresh install), return nothing gracefully — the reviewer proceeds on `repo-dna` + `review-memory` alone.
- No secrets/PII in index files.
- Index mode writes files; retrieve mode reads only. Neither posts to GitHub.
