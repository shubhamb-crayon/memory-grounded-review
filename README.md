# Repository Memory for Claude Code

> **"GitHub remembers the code. Repository Memory remembers why."**

A persistent **memory + context layer** that makes Claude Code reviews repository-specific, cheaper, and consistent — built entirely out of Claude Code's own primitives and the repo itself. **No proprietary backend.**

Generic AI review is stateless, generic, architecture-blind, amnesiac about history, expensive at scale, and repetitive. The knowledge that would fix all six already lives in your merged PRs, comments, docs, lint/CI config, and git history. Repository Memory captures it into a small set of version-controlled files the repo carries with it, and teaches Claude Code to read, apply, and update those files automatically on every PR.

---

## Two design commitments

1. **Memory = repo-resident files.** Everything learned is stored under `.claude/memory/` as markdown + JSON, committed to the repo. It's free, durable, diffable, reviewable (a change to a standard is a normal PR diff), and travels with the repo.
2. **Engine = Claude Code primitives.** The behavior is expressed as **skills** (plus subagents and hooks), packaged as this **plugin**. Claude Code is the runtime. If it would normally be a microservice, here it's a skill that calls `git`/`gh` and writes a file.

| We ship (text & config) | We never build (we reuse) |
|---|---|
| This **plugin** (skills, subagents, hooks, commands) | The LLM / reasoning → Claude Code |
| A **memory file schema** under `.claude/memory/` | The data store → git + GitHub |
| Two **GitHub Actions workflows** | PR/diff/comment access → GitHub MCP / `gh` |
| A **`CLAUDE.md` template** | Indexing / retrieval → Claude executing our skills |
| Token-budget + risk rules (text in skills) | Context cost reduction → Anthropic **prompt caching** |

---

## What's in this plugin

```
repo-memory/
├── .claude-plugin/
│   ├── plugin.json              # plugin manifest
│   └── marketplace.json         # one-plugin marketplace catalog
├── skills/                      # THE ENGINE — all logic lives here
│   ├── repo-dna/                # derive conventions (confidence + evidence)
│   ├── repo-graph/              # lightweight dependency graph, build + incremental
│   ├── review-memory/           # mine PR threads → patterns + reviewer prefs
│   ├── similar-pr/              # markdown PR index + top-3 recall (no vector DB)
│   ├── context-pack/            # selection + compression + cache-ordered assembly
│   ├── pr-review/               # orchestrator: risk-classify → pack → review → comment
│   ├── refresh-memory/          # /refresh-memory command
│   ├── update-memory/           # /update-memory command
│   └── bootstrap-memory/        # /bootstrap-memory — one-step install into a repo
├── agents/
│   ├── security-deep-dive.md    # isolated high-risk pass
│   └── memory-indexer.md        # cheap-model grunt work (scanning / indexing)
├── hooks/
│   ├── hooks.json               # approval gate + secret-read block + Stop trigger
│   └── scripts/                 # the hook scripts
├── templates/                   # COPIED INTO YOUR REPO at install
│   ├── CLAUDE.md                # points Claude at the memory + non-negotiables
│   ├── memory/                  # seed .claude/memory/ tree (schema-correct examples)
│   ├── MEMORY-STATUS.md         # the generated "dashboard" (markdown)
│   └── workflows/               # pr-review.yml + memory-update.yml
└── reference/                   # shared knowledge the skills read on demand
    ├── memory-schema.md         # full file schema spec
    └── token-strategy.md        # §10 caching + budget rules
```

After install, plugin skills are namespaced: `/repo-memory:pr-review`, `/repo-memory:refresh-memory`, `/repo-memory:update-memory`, `/repo-memory:bootstrap-memory`. The engine skills (`repo-dna`, `repo-graph`, `review-memory`, `similar-pr`, `context-pack`) are model-invoked — Claude auto-selects them by task context.

---

## Install

### 1. Add the marketplace and install the plugin

```bash
# In Claude Code (interactive)
/plugin marketplace add your-org/repo-memory
/plugin install repo-memory@repo-memory-marketplace
```

Or test locally without installing:

```bash
claude --plugin-dir /path/to/repo-memory
```

### 2. Bootstrap a repository (one step)

From inside the repo you want to add memory to:

```
/repo-memory:bootstrap-memory
```

This copies the `CLAUDE.md` template, scaffolds `.claude/memory/`, drops the two GitHub Actions workflows into `.github/workflows/`, and then offers to run the first `/repo-memory:refresh-memory` to populate the memory from your code and history.

> Prefer scripting it? `scripts/install-into-repo.sh /path/to/target-repo` does the file copy non-interactively.

### 3. Set the CI secret

Add `ANTHROPIC_API_KEY` (or `CLAUDE_CODE_OAUTH_TOKEN`) to the target repo's Actions secrets so the workflows can run.

---

## How it works — two loops, both just Claude Code

**Loop A — Local developer loop (interactive).** Run `claude` in the repo. `CLAUDE.md` auto-loads and points at `.claude/memory/`. Invoke `/repo-memory:pr-review` on a branch; Claude classifies risk, assembles compressed context, and reviews. `/repo-memory:refresh-memory` re-derives conventions/graph on demand. Memory edits land as normal commits.

**Loop B — CI loop (automated, the team default).** Powered by the official [`anthropics/claude-code-action`](https://github.com/anthropics/claude-code-action), which runs the full Claude Code runtime inside a GitHub Actions runner.

```
PR opened/updated ─► claude-code-action ─► /pr-review
                                            ├─ risk classify (changed files)
                                            ├─ context-pack  (cached memory prefix + diff)
                                            └─ inline comments on the diff
PR merged ─────────► claude-code-action ─► /update-memory
                                            ├─ review-memory  (mine the thread)
                                            ├─ repo-graph update (touched nodes)
                                            ├─ similar-pr index (add this PR)
                                            └─ commit .claude/memory/* back to repo
```

- `pr-review.yml` → on `pull_request: [opened, synchronize]`. Read on contents, write on pull-requests. Posts inline comments on exact diff lines. Guarded so the bot never reviews itself.
- `memory-update.yml` → on `pull_request: closed` **and** `merged == true`. Runs the memory-update skills and **commits** refreshed memory back (`contents: write`). This is how memory stays fresh with zero human upkeep.

---

## The five layers (v1 scope)

| Layer | v1 status | Artifact | Skill |
|---|---|---|---|
| 1. Repository DNA (conventions) | In v1 | `repo-dna.md` | `repo-dna` |
| 2. Review Memory (how the team reviews) | In v1 | `review-memory.md` | `review-memory` |
| 3. Knowledge Graph (architecture) | In v1, lightweight | `architecture-graph.json` | `repo-graph` |
| 4. Similar-PR Engine (reuse history) | In v1 (markdown + reasoning recall) | `pr-index/` | `similar-pr` |
| 5. Repository Evolution (drift → standard) | Deferred to Phase 2 | — | — |

---

## Token strategy in one line

**Cache the stable, send only the delta, never send what isn't relevant.** The memory bundle (repo summary + relevant rules + relevant patterns + impact subgraph + top-3 similar PRs) goes in a **stable, cached prefix**; the **diff goes last** as the dynamic suffix. On warm caches, the bundle bills at the ~10% read rate. Full detail: [`reference/token-strategy.md`](reference/token-strategy.md).

---

## Safety

- **Bot-loop guard:** workflows skip when the actor is `claude[bot]`.
- **Secret protection:** a `PreToolUse` hook blocks reads of `.env` and secret paths.
- **Human approval on standards:** every change to a memory file is a normal PR a human approves or rejects.
- **Least privilege CI:** review job reads contents / writes PRs; only the merge job writes contents.

---

## License

MIT — see [`LICENSE`](LICENSE).

Before distributing, replace the `your-org/repo-memory` placeholders in `plugin.json`, `marketplace.json`, `README.md`, and both workflow templates with your real repository, and update the author/owner fields.
