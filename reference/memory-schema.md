# Memory file schema

The data layer is the repo. Everything Memory-Grounded Review "knows" lives in these files, committed under `.claude/memory/`. They are small, human-readable, and PR-reviewable. Skills read and write them; humans approve changes via normal PRs.

```
.claude/
  memory/
    repo-dna.md             # Layer 1 — conventions & rules (confidence + evidence)
    review-memory.md        # Layer 2 — recurring review patterns + reviewer prefs
    architecture-graph.json # Layer 3 — lightweight dependency graph (nodes + edges)
    pr-index/               # Layer 4 — one compact .md per past PR
      2026-0612-PR-1421.md
      ...
    summaries/
      repo-summary.md       # ~500-token compressed repo overview (cached prefix)
      files/<path>.md       # ~100-token per-file summary for important files
  MEMORY-STATUS.md          # generated freshness/health dashboard
CLAUDE.md                   # points Claude at the above + non-negotiable rules
```

Keep every file small. Size discipline is what keeps the cached prefix cheap (see `token-strategy.md`). When a file grows, **knowledge aging** (in `review-memory` / `repo-dna`) drops low-confidence, stale entries.

---

## `repo-dna.md` — Layer 1: Repository DNA

Conventions and rules the repo actually follows (not textbook best practice). Written by the `repo-dna` skill. Each rule carries: **description, confidence (0.0–1.0), supporting evidence (file/PR links), and an example.**

Format — one `###` block per rule, grouped by area:

```markdown
## Conventions: API

### API responses use the `Result<T, ApiError>` envelope
- **id:** api-result-envelope
- **confidence:** 0.92
- **status:** active            <!-- active | aging | deprecated -->
- **area:** api
- **tags:** [api, errors, typescript]
- **evidence:** src/api/users.ts:L40-58, src/api/orders.ts:L22, PR #1387
- **rule:** Endpoints never throw raw; they return `Result.ok(data)` or `Result.err(new ApiError(...))`.
- **example:**
  ```ts
  return Result.err(new ApiError("NOT_FOUND", `user ${id}`));
  ```
- **rationale:** Uniform error handling at the gateway; PR #1387 rejected a raw throw.
- **last_seen:** 2026-06-12
```

Confidence guidance: `>= 0.85` strong (apply firmly), `0.6–0.85` apply as a suggestion, `< 0.6` mention only / candidate. Aging lowers confidence over time unless re-observed (`last_seen` refreshed).

---

## `review-memory.md` — Layer 2: Review Memory

How the team reviews: recurring review comments and reviewer preferences mined from PR threads by `review-memory`. Each pattern carries: **the pattern, occurrence count, accepted/rejected counts, confidence, and classification** (team convention vs. individual reviewer preference vs. temporary trend).

```markdown
## Review patterns

### Prefer dependency injection over module-level singletons
- **id:** di-over-singleton
- **kind:** team-convention        <!-- team-convention | reviewer-preference | temporary-trend -->
- **occurrences:** 14
- **accepted:** 12
- **rejected:** 2
- **confidence:** 0.86
- **tags:** [architecture, testing, di]
- **evidence:** PR #1402 (thread), PR #1377, PR #1290
- **note:** Raised most often by @aravind on service-layer changes. Accepted when it improves testability; rejected twice for trivial scripts.
- **last_seen:** 2026-06-10

## Reviewer preferences

### @aravind — wants tests in the same PR as the change
- **kind:** reviewer-preference
- **occurrences:** 9
- **confidence:** 0.78
- **tags:** [testing, process]
- **last_seen:** 2026-06-09
```

Aging rule: each pattern's confidence decays by a fixed factor per N days unless re-observed; patterns under the floor are moved to a `## Archived` section and excluded from the cached bundle.

---

## `architecture-graph.json` — Layer 3: Knowledge Graph

A **lightweight** dependency graph — dependency edges only, used to expand the "impact set" (changed nodes + direct neighbors) for blast-radius analysis. Not a graph-database project. Built and incrementally updated by `repo-graph`.

```json
{
  "version": 1,
  "generated_at": "2026-06-12T18:02:00Z",
  "node_count": 0,
  "edge_count": 0,
  "nodes": [
    {
      "id": "svc:auth",
      "kind": "service",
      "path": "src/auth",
      "summary_ref": "summaries/files/src/auth.md",
      "risk": "high",
      "tags": ["auth", "security"]
    },
    {
      "id": "tbl:users",
      "kind": "table",
      "path": "db/migrations",
      "risk": "high",
      "tags": ["db"]
    },
    {
      "id": "ep:POST /login",
      "kind": "endpoint",
      "path": "src/api/login.ts",
      "risk": "high",
      "tags": ["auth", "api"]
    }
  ],
  "edges": [
    { "from": "ep:POST /login", "to": "svc:auth", "kind": "calls" },
    { "from": "svc:auth", "to": "tbl:users", "kind": "reads" }
  ]
}
```

Node `kind`: `service | lib | module | table | endpoint | queue | topic | job | external`.
Edge `kind`: `calls | imports | reads | writes | publishes | subscribes | triggers | depends_on`.
Node `risk`: `low | medium | high` — feeds the risk-based pipeline.
`summary_ref` (optional): relative path under `.claude/memory/` to the node's file summary.

**Incremental update contract:** on merge, `repo-graph` only adds/updates/removes nodes and edges for touched files. A full rebuild runs on first install and periodically in CI.

---

## `pr-index/` — Layer 4: Similar-PR Engine

One compact markdown file per past PR. Filename: `YYYY-MMDD-PR-<number>.md`. Written by `similar-pr` on merge; read (top-3 by reasoning) at review time. No embeddings / vector DB in v1.

```markdown
---
pr: 1421
title: "Add rate limiting to login endpoint"
merged_at: 2026-06-12
author: priya
files: [src/api/login.ts, src/middleware/rate-limit.ts, db/migrations/0042_rl.sql]
nodes: [ep:POST /login, svc:auth, tbl:users]
tags: [auth, api, security, rate-limiting]
outcome: merged
follow_up: none            # none | incident:<link> | revert:<pr> | hotfix:<pr>
---

## Intent
Throttle brute-force login attempts.

## Key review outcomes
- Reviewer required a per-IP + per-account dual limit (PR #1421 thread).
- Migration must be reversible — accepted after adding a `down` step.

## Lessons / gotchas
- `rate-limit.ts` is in the hot path of `svc:auth`; changes here are high-risk.
```

Retrieval is Claude reading this folder and reasoning about similarity by `tags` / `nodes` / `files` overlap with the PR under review.

---

## `summaries/` — compressed context for the cached prefix

- `summaries/repo-summary.md` — a ~500-token overview of the repo (purpose, top-level layout, stack, critical areas). Regenerated by `repo-dna` / `repo-graph`. Forms part of the stable cached prefix.
- `summaries/files/<path>.md` — a ~100-token summary per *important* file (high-risk or high-fan-in nodes), mirroring the source path. Only touched files' summaries are pulled into a given review.

---

## `MEMORY-STATUS.md` — the dashboard

A single generated markdown file (refreshed by `update-memory`) showing memory freshness, last update, rule/pattern counts, and confidence distribution. Rendered by GitHub's normal markdown view — zero front-end. See `templates/MEMORY-STATUS.md` for the layout.

---

## Invariants every skill must keep

1. **Small + stable.** Prefer editing existing entries over appending duplicates. Run aging before writing.
2. **Evidence or it didn't happen.** Every rule/pattern cites file lines or PR numbers.
3. **Confidence is honest.** New/weakly-supported entries get low confidence, not high.
4. **Diff-friendly.** Stable ordering (by id), one entry per block, so PR diffs are readable.
5. **No secrets.** Never write `.env` contents, tokens, or PII into memory files.
