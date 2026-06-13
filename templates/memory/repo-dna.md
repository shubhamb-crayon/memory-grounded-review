# Repository DNA

> Conventions and rules **this repo actually follows**, with confidence + evidence.
> Maintained by the `repo-dna` skill. This is a **seed example** — `/repo-memory:refresh-memory`
> replaces it with rules derived from your real code, PRs, and lint/CI config.
>
> Confidence: ≥ 0.85 apply firmly · 0.6–0.85 suggest · < 0.6 mention only.
> Status: `active` · `aging` (confidence decaying, re-confirm) · `deprecated`.

_Last refreshed: 2026-06-12 · rules: 4 (3 active, 1 aging)_

## Conventions: API

### API responses use the `Result<T, ApiError>` envelope
- **id:** api-result-envelope
- **confidence:** 0.92
- **status:** active
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

## Conventions: Database

### Migrations must be reversible
- **id:** reversible-migrations
- **confidence:** 0.88
- **status:** active
- **area:** db
- **tags:** [db, migrations]
- **evidence:** db/migrations/0041_orders.sql, PR #1421, PR #1356
- **rule:** Every migration ships a `down` step; irreversible operations require an explicit `-- IRREVERSIBLE` comment and a reviewer sign-off.
- **example:**
  ```sql
  -- up
  ALTER TABLE orders ADD COLUMN status text NOT NULL DEFAULT 'pending';
  -- down
  ALTER TABLE orders DROP COLUMN status;
  ```
- **rationale:** Enables safe rollbacks; PR #1421 was held until a `down` step was added.
- **last_seen:** 2026-06-12

## Conventions: Testing

### New service-layer code ships with unit tests in the same PR
- **id:** tests-with-change
- **confidence:** 0.83
- **status:** active
- **area:** testing
- **tags:** [testing, process]
- **evidence:** PR #1402, PR #1377, CI config .github/workflows/ci.yml (coverage gate 80%)
- **rule:** Changes under `src/services/**` include matching tests under `test/services/**`; CI enforces ≥ 80% coverage.
- **last_seen:** 2026-06-10

## Conventions: Logging

### Use the structured `logger`, never `console.log`
- **id:** structured-logging
- **confidence:** 0.64
- **status:** aging
- **area:** observability
- **tags:** [logging, observability]
- **evidence:** src/lib/logger.ts, PR #1290 (1 comment)
- **rule:** Emit logs via `logger.info/warn/error` with a context object; `console.log` is flagged in review.
- **note:** Weakly evidenced — confirm on the next few PRs or it will be archived.
- **last_seen:** 2026-05-28
