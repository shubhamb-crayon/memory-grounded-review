---
name: similar-pr
description: Index merged pull requests as compact markdown files under .claude/memory/pr-index/, and at review time retrieve the top-3 most similar prior PRs (by tag / node / file overlap, via reasoning — no embeddings or vector DB). Modes — BACKFILL (bulk-index history, called by refresh-memory), INDEX (one merged PR, called by update-memory), and RETRIEVE (at review time).
---

# similar-pr — index & recall past PRs

Reuse history. Most changes rhyme with something already merged. **Read the schema first:** `${CLAUDE_PLUGIN_ROOT}/reference/memory-schema.md` (`pr-index/` section). Files are named `YYYY-MMDD-PR-<number>.md`.

> The shipped seed `2026-0612-PR-1421.md` is an **example** — if it doesn't match a real PR in this repo, delete it.

## Mode A — BACKFILL (first install / full refresh)
1. List recent merged PRs newest-first:
   ```bash
   gh pr list --state merged --limit 100 --json number,title,mergedAt,author,files,labels
   ```
2. For each (route the bulk work to the **`memory-indexer`** subagent to stay cheap), build one compact index file: resolve changed files → `nodes` via `architecture-graph.json`, derive `tags`, capture `outcome` and any `follow_up` (incident/revert/hotfix) you can detect from labels or linked issues. Body ≈ 100–150 tokens: **Intent**, **Key review outcomes** (cross-ref `review-memory`/`repo-dna` ids), **Lessons/gotchas**.
3. Cap the first backfill at ~100 PRs (state the cap); later merges extend the index incrementally. Stable field order so diffs stay clean.

## Mode B — INDEX (on merge, via update-memory)
Append a single `pr-index/YYYY-MMDD-PR-<n>.md` for the just-merged PR, same shape as above.

## Mode C — RETRIEVE (at review time)
1. Compute the candidate PR's signature: changed files → nodes (via the graph) → tags.
2. Score indexed PRs by overlap, weighted **shared nodes > shared files > shared tags**, with a small recency bonus and a boost for any PR carrying an incident/revert/hotfix `follow_up` in the same area.
3. Return the **top 3**: title, why-similar, and the one-line lesson. Don't dump whole files.

> Retrieval is just reading `pr-index/` and reasoning about similarity. **No embeddings / vector store in v1.** Only consider a managed embedding service if measured recall is insufficient.

## Guardrails
- Top-k = 3 at review time; never load the whole index into a review.
- If `pr-index/` is empty, return nothing gracefully — the reviewer proceeds on `repo-dna` + `review-memory`.
- No secrets/PII in index files. Index/backfill write files; retrieve reads only. Neither posts to GitHub.
