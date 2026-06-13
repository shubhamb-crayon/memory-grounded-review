<!-- ~500-token compressed repo overview. Part of the stable, cached prefix. Seed example. -->
# Repo summary

**Purpose:** Order-management backend for an e-commerce platform. Exposes a REST API for authentication and order lifecycle, backed by Postgres.

**Stack:** TypeScript (strict), Node.js, Express-style routing, Postgres via SQL migrations, Vitest for tests. CI on GitHub Actions with an 80% coverage gate and ESLint.

**Top-level layout:**
- `src/api/**` — HTTP endpoints (thin); translate requests → service calls, return the `Result<T, ApiError>` envelope.
- `src/services/**` — business logic. `auth` (high-risk: login, sessions, tokens) and `orders`.
- `src/middleware/**` — cross-cutting concerns; `rate-limit.ts` is in the auth hot path (high-risk).
- `src/lib/**` — shared utilities (`logger`, config). Low-risk, high fan-in.
- `db/migrations/**` — reversible SQL migrations (`up`/`down`).
- `test/**` — mirrors `src/**`.

**Critical / high-risk areas:** anything under `src/services/auth`, `src/middleware/rate-limit.ts`, `db/migrations`, and the `POST /login` endpoint. Changes here warrant deeper review, more graph neighbors, and a security pass.

**Conventions in force (see `repo-dna.md`):** `Result<T, ApiError>` response envelope; reversible migrations; tests in the same PR as service-layer changes; structured `logger` over `console.log`.

**How the team reviews (see `review-memory.md`):** DI over singletons; validate/sanitize input at the boundary; reviewers care about migration `down` steps and same-PR tests.
