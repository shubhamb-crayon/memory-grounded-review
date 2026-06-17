---
name: pr-review
description: Review a pull request or the current branch, grounded in repository memory, with risk-based depth and prompt-cache-optimized context. Risk-classifies changed files, assembles context via context-pack, reviews against repo-dna rules + review-memory patterns + similar past PRs + the architecture impact set, escalates high-risk files to a deeper security pass, and posts findings as inline comments on the exact diff lines. Use as /memory-grounded-review:pr-review, when asked to review a PR/branch/diff, or from the pr-review.yml CI workflow.
---

# pr-review — memory-grounded, risk-based review

You are the orchestrator. You do not give generic feedback — you review against what **this repo** has decided, recall how similar changes went, and reason about blast radius. You spend tokens in proportion to risk.

## Inputs & setup
- Target: a PR number, a branch, or the working tree diff. In CI the branch is already checked out and `REPO` / `PR NUMBER` are provided in the prompt.
- Get the diff: `gh pr diff <n>` / `git diff <base>...<head>` (or GitHub MCP). Get the file list for classification.
- Memory lives under `.claude/memory/` (auto-pointed by `CLAUDE.md`).

## Step 1 — Risk-classify the changed files
Assign each changed file a class; the PR's class is the max:
- **Low** — README, comments, docs, tests, config-only. Shallow conventions check, smallest budget. May route to the cheaper `memory-indexer` subagent.
- **Medium** — utilities, models, API contracts, ordinary domain logic. Standard review.
- **High** — auth, security, DB migrations, infrastructure/IaC, payments, critical services, or any file mapped to a `risk: high` node in `architecture-graph.json`. Deep review: more graph neighbors (2 hops), more similar PRs, **and an optional `security-deep-dive` subagent pass**.

## Step 2 — Assemble context (cheap & cached)
Invoke **`context-pack`** with the diff + risk class. It returns the ordered bundle: repo summary → relevant `repo-dna` rules → relevant `review-memory` patterns → impact subgraph + touched-file summaries → top-3 similar PRs → **cache breakpoint** → the diff. Do not pull the whole tree; trust the pack. (Spec: `${CLAUDE_PLUGIN_ROOT}/reference/token-strategy.md`.)

## Step 3 — Review against memory
Go file-by-file / hunk-by-hunk. For each potential finding, prefer grounding it in memory or evidence:
- **Convention violations:** cite the `repo-dna` rule id (e.g. "violates `api-result-envelope` (conf 0.92): endpoints must return `Result`, not throw"). Apply ≥ 0.85 firmly; 0.6–0.85 as a suggestion; < 0.6 mention lightly.
- **Settled decisions:** if `review-memory` already covers it, apply it — and **do not re-litigate** something the team has decided (that's the whole point).
- **Blast radius:** use the impact set to flag downstream effects ("this changes `svc:auth`, which `svc:orders` calls — check the order flow").
- **History:** if a similar past PR caused an incident/revert, surface that explicitly.
- **Genuine new bugs:** still call out real correctness/security/perf issues even if memory is silent — then consider whether they should become memory (handled later by `update-memory`).
For high-risk files, run the `security-deep-dive` subagent and fold its findings in.

## Step 4 — Decide severity & dedupe
Rate each finding **CRITICAL / HIGH / MEDIUM / LOW / NIT**. Drop low-value nits the team has historically rejected (check `review-memory` rejected counts). One comment per issue; group related ones.

## Step 5 — Post (respecting the approval non-negotiable)
- **Interactive (`/memory-grounded-review:pr-review`):** present the findings list and **wait for approval** before posting. The plugin's `PreToolUse` hook also gates comment-posting tools. After approval, post inline comments on the exact lines.
- **CI (`pr-review.yml`):** post inline comments with `mcp__github_inline_comment__create_inline_comment` (or `gh pr comment` for the summary). Post a brief top-level summary: risk class, counts by severity, and which memory rules/PRs were applied. **Only post GitHub comments — don't dump the review as chat text.**

## Step 6 — Leave a trail for replay
Note what you reviewed (commit SHA, findings) so a later `synchronize` only re-reviews the new delta (see `context-pack` replay).

## Output contract
Each inline comment: **[SEVERITY] finding — why (cite rule id / PR # / evidence) — suggested fix.** Keep it specific and kind; this should read like your most senior reviewer on a good day, not a linter.

## Guardrails
- Never post without approval (interactive) / outside the workflow's permissions (CI).
- Never read secrets. Never review the bot's own commits (the workflow guards `claude[bot]`).
- Ground findings; avoid generic best-practice lectures the repo hasn't adopted.
