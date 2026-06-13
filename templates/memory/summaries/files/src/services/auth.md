<!-- ~100-token summary. Seed example. -->
# src/services/auth — auth service

Core authentication/session logic. **High-risk, high fan-in.** Verifies credentials, issues and
validates session tokens, reads `tbl:users`. Imported by `ep:POST /login` and called by
`svc:orders`. Uses structured `logger` (never `console.log`). Changes here expand the impact set to
all direct neighbors and should trigger the `security-deep-dive` subagent. Common pitfalls: timing
side-channels in credential checks, token expiry/refresh handling, and logging sensitive fields.
