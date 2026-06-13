---
name: bootstrap-memory
description: One-step setup of Repository Memory in the current repo — copies the CLAUDE.md template (merging into any existing one), scaffolds the .claude/memory/ tree, installs the pr-review.yml and memory-update.yml GitHub Actions workflows, then offers to run the first /repo-memory:refresh-memory. Use as /repo-memory:bootstrap-memory or when asked to set up / install / initialize Repository Memory in a repository.
---

# bootstrap-memory — install Repository Memory into a repo

Gets a repository from zero to "memory-ready" in one step. Idempotent: safe to re-run; it won't clobber human edits.

## Procedure
1. **Confirm context.** Ensure you're at the root of a git repo (`git rev-parse --show-toplevel`). If not, ask the user to `cd` there.

2. **Copy templates.** Easiest path — run the bundled installer:
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/install-into-repo.sh" "$(git rev-parse --show-toplevel)"
   ```
   It copies (without overwriting existing files):
   - `templates/memory/**` → `.claude/memory/**` (seed examples, schema-correct)
   - `templates/MEMORY-STATUS.md` → `MEMORY-STATUS.md`
   - `templates/workflows/{pr-review,memory-update}.yml` → `.github/workflows/`
   - `templates/CLAUDE.md` → `CLAUDE.md` (see merge rule below)

3. **Merge `CLAUDE.md` carefully.** If the repo has no `CLAUDE.md`, copy the template. If it already has one, **insert the block between the `<!-- BEGIN repo-memory -->` / `<!-- END repo-memory -->` markers** without disturbing the rest. On re-run, replace only that marked block so updates land cleanly.

4. **Tell the user what's left to do:**
   - Add `ANTHROPIC_API_KEY` (or `CLAUDE_CODE_OAUTH_TOKEN`) to the repo's GitHub Actions secrets so the workflows run.
   - Replace any `your-org/...` placeholders if they forked the plugin.
   - The seed `.claude/memory/**` files are **examples** — they'll be replaced by real, derived content in the next step.

5. **Offer the first refresh.** Ask whether to run **`/repo-memory:refresh-memory`** now to derive real conventions + the architecture graph from this repo. If yes, hand off to that skill.

6. **Report.** List exactly what was created vs. skipped (already existed), and the manual steps remaining.

## Guardrails
- **Never overwrite** existing memory files or a hand-written `CLAUDE.md` body — only fill gaps and update the marked block.
- Don't commit automatically; leave everything staged so the human reviews the initial setup as a normal PR.
- Never write secrets anywhere.
