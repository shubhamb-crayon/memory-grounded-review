# Per-file summaries

`summaries/files/<path>.md` holds a **~100-token** summary for each *important* file — high-risk
nodes or high-fan-in modules. The path mirrors the source path (e.g. `src/api/login.ts` →
`summaries/files/src/api/login.md`).

These are referenced from `architecture-graph.json` via each node's `summary_ref`, and only the
**touched files'** summaries are pulled into a given review (see `reference/token-strategy.md`).

Written/refreshed by `repo-dna` and `repo-graph`. The two files here are seed examples.
