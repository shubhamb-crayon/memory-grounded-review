#!/usr/bin/env bash
#
# PreToolUse guard: enforce the "never post a comment without approval" non-negotiable.
# Interactive sessions must explicitly confirm before any GitHub comment/review is posted.
#
# Design notes:
#  - Runs on Bash and on the GitHub inline-comment MCP tool, and SELF-FILTERS to the
#    posting commands (rather than relying on the best-effort hook `if` matcher).
#  - In CI (claude-code-action) there is no human to approve, so the workflow's
#    least-privilege token + --allowedTools govern and we step aside.
#  - jq-OPTIONAL and fails SAFE: if intent can't be determined precisely, it still asks.
#
set -uo pipefail

input="$(cat 2>/dev/null || true)"

# CI: let the workflow govern (no human in the loop).
if [ "${GITHUB_ACTIONS:-}" = "true" ] || [ "${CI:-}" = "true" ]; then
  exit 0
fi

tool=""
cmd=""
if command -v jq >/dev/null 2>&1; then
  tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
fi

# Commands/tools that post to GitHub and therefore require confirmation.
POST_RE='gh[[:space:]]+pr[[:space:]]+(comment|review)|gh[[:space:]]+issue[[:space:]]+comment|gh[[:space:]]+api[^|]*(-X|--method)[[:space:]]*"?(POST|PUT|PATCH|DELETE)|create_inline_comment'

needs_approval=0
case "$tool" in
  mcp__github_inline_comment__create_inline_comment)
    needs_approval=1 ;;
  Bash)
    printf '%s' "$cmd" | grep -Eqi "$POST_RE" && needs_approval=1 ;;
  "")
    # jq unavailable (tool unknown): scan the raw input as a fallback.
    printf '%s' "$input" | grep -Eqi "$POST_RE" && needs_approval=1 ;;
esac

if [ "$needs_approval" = "1" ]; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Repository Memory: confirm before posting this comment/review to GitHub. (Non-negotiable: never post without approval.)"}}'
fi
exit 0
