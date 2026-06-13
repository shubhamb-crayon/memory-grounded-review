# Review Memory

> How this team reviews: recurring review patterns and individual reviewer preferences,
> mined from PR threads by the `review-memory` skill. This is a **seed example**.
>
> `kind`: `team-convention` · `reviewer-preference` · `temporary-trend`.
> Aging: confidence decays unless re-observed; entries under the floor move to **Archived**.

_Last mined: 2026-06-10 · patterns: 3 active · 1 archived_

## Review patterns

### Prefer dependency injection over module-level singletons
- **id:** di-over-singleton
- **kind:** team-convention
- **occurrences:** 14
- **accepted:** 12
- **rejected:** 2
- **confidence:** 0.86
- **tags:** [architecture, testing, di]
- **evidence:** PR #1402 (thread), PR #1377, PR #1290
- **note:** Raised most often on service-layer changes. Accepted when it improves testability; rejected twice for trivial one-off scripts.
- **last_seen:** 2026-06-10

### Validate and sanitize all external input at the boundary
- **id:** validate-at-boundary
- **kind:** team-convention
- **occurrences:** 11
- **accepted:** 11
- **rejected:** 0
- **confidence:** 0.90
- **tags:** [security, api, validation]
- **evidence:** PR #1421, PR #1399, PR #1360
- **note:** Especially enforced on `src/api/**` and `src/middleware/**`.
- **last_seen:** 2026-06-12

### Avoid `any` in new TypeScript
- **id:** no-any
- **kind:** temporary-trend
- **occurrences:** 5
- **accepted:** 4
- **rejected:** 1
- **confidence:** 0.62
- **tags:** [typescript, types]
- **evidence:** PR #1410, PR #1405
- **note:** Picked up after the strict-mode migration; watch whether it becomes a standing convention.
- **last_seen:** 2026-06-08

## Reviewer preferences

### @aravind — wants tests in the same PR as the change
- **id:** pref-aravind-tests
- **kind:** reviewer-preference
- **occurrences:** 9
- **confidence:** 0.78
- **tags:** [testing, process]
- **evidence:** PR #1402, PR #1377
- **last_seen:** 2026-06-09

### @priya — flags missing migration `down` steps
- **id:** pref-priya-migrations
- **kind:** reviewer-preference
- **occurrences:** 6
- **confidence:** 0.74
- **tags:** [db, migrations]
- **evidence:** PR #1421, PR #1356
- **last_seen:** 2026-06-12

## Archived

### Wrap all dates in the legacy `DateUtil` helper
- **id:** legacy-dateutil
- **kind:** temporary-trend
- **confidence:** 0.21
- **tags:** [dates, legacy]
- **note:** Superseded by native `Temporal` adoption (PR #1388). Kept for history; excluded from review context.
- **last_seen:** 2026-03-02
