#!/usr/bin/env bash
#
# PreToolUse guard: deny attempts to read/echo secret files.
# Reads the hook JSON on stdin; emits a deny decision for secret paths.
# Portable regex (no \b) so it works on both GNU (CI) and BSD (macOS) grep.
#
set -euo pipefail

input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty')"

case "$tool" in
  Read|Edit|Write) target="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')" ;;
  Bash)            target="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')" ;;
  *)               exit 0 ;;
esac

[ -z "$target" ] && exit 0

# Allow well-known non-secret env templates.
if printf '%s' "$target" | grep -Eiq '\.env\.(example|sample|template|dist|defaults?)([^A-Za-z0-9]|$)'; then
  exit 0
fi

# Secret path / file patterns. Boundaries use explicit character classes (no \b) for
# GNU+BSD grep portability. The "after" class for the secrets segment excludes whitespace
# so the English word "secret"/"secrets" in a commit message isn't treated as a path.
SECRET_RE='(^|[^A-Za-z0-9._-])\.env([^A-Za-z0-9_]|$)|\.env\.[A-Za-z0-9_-]+|\.pem([^A-Za-z0-9]|$)|(^|[^A-Za-z0-9])id_rsa|(^|[^A-Za-z0-9_])\.?secrets?([/._-]|$)|credentials|\.p12([^A-Za-z0-9]|$)|\.pfx([^A-Za-z0-9]|$)|\.keystore|\.key([^A-Za-z0-9]|$)|service[_-]account[^[:space:]]*\.json'

if printf '%s' "$target" | grep -Eiq "$SECRET_RE"; then
  jq -n --arg t "$target" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("Repository Memory blocked access to a likely secret path (" + $t + "). Secrets must never be read or copied into memory files.")
    }
  }'
  exit 0
fi

exit 0
