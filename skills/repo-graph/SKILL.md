---
name: repo-graph
description: Build or incrementally update a lightweight repository dependency graph (services, libs, modules, tables, endpoints, queues/topics, jobs and the edges between them) stored as .claude/memory/architecture-graph.json. Use on first install / refresh to build it fully, and on merge to update only the touched nodes/edges. The review pipeline uses it to compute a change's "impact set" (changed nodes + direct neighbors) for blast-radius analysis.
---

# repo-graph — build & update the architecture graph

You maintain a **deliberately lightweight** dependency graph: enough to answer "what does this change touch?" without becoming a graph-database project. It is the substrate for impact-set (blast-radius) expansion during review.

**Output:** `.claude/memory/architecture-graph.json`. **Read the schema first:** `${CLAUDE_PLUGIN_ROOT}/reference/memory-schema.md` (the `architecture-graph.json` section defines node `kind`, edge `kind`, and `risk`).

## Two modes

### A. Full build (first install, refresh, periodic CI)
1. **Discover nodes.** Walk the repo and identify:
   - **services / modules / libs** — top-level units under `src/**` (or language equivalent).
   - **endpoints** — route declarations (`app.get/post`, decorators, OpenAPI, framework routers).
   - **tables** — from migrations / ORM models / schema files.
   - **queues / topics / jobs** — message producers/consumers, cron/worker definitions.
   - **external** — third-party services called over the network.
   Prefer routing this scan to the `memory-indexer` subagent (cheaper model, keeps main context clean).
2. **Discover edges** by following imports/requires, function calls across module boundaries, DB reads/writes, publish/subscribe, and IaC wiring. Use edge `kind` from the schema (`calls`, `imports`, `reads`, `writes`, `publishes`, `subscribes`, `triggers`, `depends_on`).
3. **Annotate risk.** Mark `risk: high` for auth, security, DB migrations, infra, payment, and anything with high fan-in. `medium` for core domain logic / API contracts. `low` for docs/config/tests.
4. **Link summaries (deterministic, full coverage).** For **every** `service` and `lib` node, plus every `risk: high` node, set `summary_ref` to `summaries/files/<path>.md` derived from the node's `path` (e.g. node `path: services/translation/...` → `summaries/files/services/translation.md`). This node list is the **worklist `repo-dna` uses to write summaries**, so every service gets one — not just the handful sampled for conventions. Don't leave service/lib nodes without a `summary_ref`.
5. **Write** the JSON with `version`, `generated_at` (UTC ISO-8601), accurate `node_count`/`edge_count`, and **stable ordering** (sort nodes by `id`, edges by `from` then `to`) so diffs are minimal.

### B. Incremental update (on merge — the default in CI)
1. Determine touched files: `git diff --name-only <base>...<head>` (or the PR file list).
2. Map touched files → affected nodes. For each:
   - **Add** new nodes/edges introduced by the change.
   - **Update** edges whose source/target dependencies changed.
   - **Remove** nodes/edges for deleted files or removed imports.
3. **Do not rebuild the whole graph.** Only mutate touched nodes/edges. Recompute `node_count`/`edge_count` and refresh `generated_at`.
4. Keep ordering stable so the commit diff shows only what actually changed.

## Impact-set helper (used by `context-pack` / `pr-review`)
Given a set of changed files → resolve to changed nodes → return **changed nodes ∪ their direct neighbors** (1 hop). For `risk: high` changed nodes, the reviewer may expand to 2 hops. This bounded expansion is what keeps review context small (see `${CLAUDE_PLUGIN_ROOT}/reference/token-strategy.md`).

## Guardrails
- Lightweight by design: edges are dependencies, not a full call graph. Don't enumerate every function.
- Deterministic output: same repo state → same JSON ordering. No timestamps inside nodes.
- Never include secrets or credentials as nodes/values.
- This skill writes only the JSON file; it posts nothing to GitHub.
