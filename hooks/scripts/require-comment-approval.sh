#!/usr/bin/env bash
#
# PreToolUse guard: enforce the "never post a comment without approval" non-negotiable.
# Interactive sessions must explicitly confirm before any GitHub comment/review is posted.
# In CI (claude-code-action), the workflow's least-privilege token + --allowedTools govern,
# and there is no human to approve, so we step aside and let the normal flow proceed.
#
set -euo pipefail

# Drain stdin (hook input) even though we don't need its contents here.
cat >/dev/null 2>&1 || true

if [ "${GITHUB_ACTIONS:-}" = "true" ] || [ "${CI:-}" = "true" ]; then
  exit 0
fi

jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: "Repository Memory: confirm before posting this comment/review to GitHub. (Non-negotiable: never post without approval.)"
  }
}'
exit 0
