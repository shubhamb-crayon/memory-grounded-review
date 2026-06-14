#!/usr/bin/env bash
#
# Stop hook (optional, non-blocking): if the session ended on a fresh merge commit,
# gently suggest refreshing repository memory. Never blocks the session from stopping.
#
set -uo pipefail

cat >/dev/null 2>&1 || true   # drain hook input

if git rev-parse --git-dir >/dev/null 2>&1; then
  # Number of parents of HEAD: a merge commit has >= 2.
  parents="$(git show -s --format='%P' HEAD 2>/dev/null | wc -w | tr -d '[:space:]')"
  if [ "${parents:-0}" -gt 1 ] 2>/dev/null; then
    echo "Repository Memory: HEAD is a merge commit — consider running /repo-memory:update-memory to learn from it."
  fi
fi

exit 0
