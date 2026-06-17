#!/usr/bin/env bash
#
# PreToolUse guard: deny attempts to read/echo secret files.
# Reads the hook JSON on stdin and emits a deny decision for secret paths.
#
# Design notes:
#  - jq-OPTIONAL: parses input with jq when available, else scans the raw stdin
#    blob (fail toward safety). Output JSON is built with printf, so jq is never
#    required to BLOCK.
#  - Portable regex (no \b) so it works on both GNU (CI) and BSD (macOS) grep.
#  - Reading SOURCE code is this tool's whole job, and source files reference
#    secrets via env vars rather than containing raw secret material — so for
#    file-path tools we allow known code extensions up front. That keeps the
#    guard from blocking legit review of files like `credentials.ts`.
#
set -uo pipefail

input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

tool=""
target=""
if command -v jq >/dev/null 2>&1; then
  tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
  case "$tool" in
    Read|Edit|Write) target="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)" ;;
    Grep)            target="$(printf '%s' "$input" | jq -r '[.tool_input.path, .tool_input.glob] | map(select(. != null)) | join(" ")' 2>/dev/null || true)" ;;
    Bash)            target="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)" ;;
    *)               exit 0 ;;
  esac
else
  # jq unavailable: scan the whole raw input (fail toward safety).
  target="$input"
fi

[ -z "$target" ] && exit 0

# Allow well-known non-secret env templates.
if printf '%s' "$target" | grep -Eiq '\.env\.(example|sample|template|dist|defaults?)([^A-Za-z0-9]|$)'; then
  exit 0
fi

# For file-path tools, allow source code: reviewing it is the job, and it won't
# contain raw secret values.
case "$tool" in
  Read|Edit|Write|Grep)
    if printf '%s' "$target" | grep -Eiq '\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|java|rb|php|c|cc|cpp|cxx|h|hpp|cs|kt|kts|swift|scala|clj|ex|exs|erl|hs|lua|pl|r|mm?|vue|svelte|sql|html?|css|scss|sass)([^A-Za-z0-9]|$)'; then
      exit 0
    fi
    ;;
esac

# Secret file / path patterns (explicit boundaries, no \b).
SECRET_RE='(^|[^A-Za-z0-9._-])\.env([^A-Za-z0-9_]|$)'                 # .env
SECRET_RE="$SECRET_RE"'|\.env\.[A-Za-z0-9_-]+'                        # .env.local, .env.production, ...
SECRET_RE="$SECRET_RE"'|\.(pem|p12|pfx|key|keystore|jks|asc|ppk)([^A-Za-z0-9]|$)'  # keys / certs
SECRET_RE="$SECRET_RE"'|(^|[^A-Za-z0-9])id_(rsa|dsa|ecdsa|ed25519)'  # SSH private keys
SECRET_RE="$SECRET_RE"'|(^|[^A-Za-z0-9_])\.?secrets?/'               # a secrets/ directory
SECRET_RE="$SECRET_RE"'|secrets?\.(json|ya?ml|ini|cfg|conf|env|properties|toml)([^A-Za-z0-9]|$)'  # secrets file
SECRET_RE="$SECRET_RE"'|(^|[^A-Za-z0-9_])\.?credentials(\.(json|ya?ml|ini|cfg|conf|properties|csv))?([^A-Za-z0-9./]|$)'  # credentials file (not credentials.ts etc.)
SECRET_RE="$SECRET_RE"'|service[_-]account[^[:space:]]*\.json'       # GCP service-account key

if printf '%s' "$target" | grep -Eiq "$SECRET_RE"; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Memory-Grounded Review blocked access to a likely secret file or path. Secrets must never be read or copied into memory files. (If this is a false positive, read the specific source file directly.)"}}'
  exit 0
fi

exit 0
