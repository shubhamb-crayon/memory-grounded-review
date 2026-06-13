<!-- ~100-token summary. Seed example. -->
# src/api/login.ts — `POST /login`

Authentication endpoint. **High-risk.** Validates credentials, then calls `svc:auth` to verify
and mint a session. Sits behind `mw:rate-limit` (per-IP + per-account, added in PR #1421). Returns
the `Result<T, ApiError>` envelope. Must validate/sanitize input at the boundary
(`review-memory: validate-at-boundary`). Touchpoints: `svc:auth`, `mw:rate-limit`, `tbl:users`.
Common pitfalls: leaking whether an account exists in error messages; bypassing the rate limiter.
