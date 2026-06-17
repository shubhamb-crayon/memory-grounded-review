# pr-index

One compact markdown file per past PR (`YYYY-MMDD-PR-<number>.md`), written by the
`similar-pr` skill — backfilled by `/memory-grounded-review:refresh-memory` and appended on
each merge by `:update-memory`. Retrieval reads this folder and reasons about similarity
(no embeddings/vector DB in v1). Format: see the plugin's `reference/memory-schema.md`.

_Empty until you run `/memory-grounded-review:refresh-memory`._
