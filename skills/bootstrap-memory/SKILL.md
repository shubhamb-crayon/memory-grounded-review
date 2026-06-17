---
name: bootstrap-memory
description: One-step setup of Memory-Grounded Review in the current repo — copies the CLAUDE.md template (merging into any existing one), scaffolds the .claude/memory/ tree, then offers to run the first /memory-grounded-review:refresh-memory. The GitHub Actions CI workflows (Loop B) are OPTIONAL and are NOT installed by default. Use as /memory-grounded-review:bootstrap-memory or when asked to set up / install / initialize Memory-Grounded Review in a repository.
---

# bootstrap-memory — install Memory-Grounded Review into a repo

Gets a repository from zero to "memory-ready" in one step. **Local-first: by default this sets up interactive use only — no GitHub Actions workflows are installed.** Idempotent: safe to re-run; it won't clobber human edits.

## Procedure
1. **Confirm context.** Ensure you're at the root of a git repo (`git rev-parse --show-toplevel`). If not, ask the user to `cd` there.

2. **Copy templates (local setup).** Run the bundled installer:
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/install-into-repo.sh" "$(git rev-parse --show-toplevel)"
   ```
   It copies (without overwriting existing files):
   - `templates/memory/**` → `.claude/memory/**` (seed examples, schema-correct)
   - `templates/MEMORY-STATUS.md` → `MEMORY-STATUS.md`
   - `templates/CLAUDE.md` → `CLAUDE.md` (see merge rule below)

   It deliberately does **not** install the GitHub Actions workflows (that's opt-in — see step 5).

3. **Merge `CLAUDE.md` carefully.** If the repo has no `CLAUDE.md`, copy the template. If it already has one, **insert the block between the `<!-- BEGIN memory-grounded-review -->` / `<!-- END memory-grounded-review -->` markers** without disturbing the rest. On re-run, replace only that marked block so updates land cleanly.

4. **Tell the user what's left to do:**
   - The `.claude/memory/**` files start as **empty skeletons** — the next step fills them with real, derived content. (Nothing fictional is installed.)
   - Replace any `shubhamb-crayon/...` placeholders if they forked the plugin.

5. **Optional — enable GitHub Actions CI (Loop B).** Only if the user explicitly wants automated review-on-PR and memory-update-on-merge. **Do not do this by default.** When asked, re-run the installer with the flag:
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/install-into-repo.sh" "$(git rev-parse --show-toplevel)" --with-ci
   ```
   Then tell them to: add `ANTHROPIC_API_KEY` (or `CLAUDE_CODE_OAUTH_TOKEN`) to the repo's Actions secrets, and set `plugin_marketplaces` in the two workflow files to their plugin repo URL. Mention that local use works fully without any of this.

6. **Offer the first refresh.** Ask whether to run **`/memory-grounded-review:refresh-memory`** now to derive real conventions + the architecture graph from this repo. If yes, hand off to that skill.

7. **Report.** List exactly what was created vs. skipped (already existed), whether CI was installed, and the manual steps remaining.

## Guardrails
- **Local-first:** never install the GitHub Actions workflows unless the user explicitly opts in.
- **Never overwrite** existing memory files or a hand-written `CLAUDE.md` body — only fill gaps and update the marked block.
- Don't commit automatically; leave everything staged so the human reviews the initial setup.
- Never write secrets anywhere.
