#!/usr/bin/env bash
#
# install-into-repo.sh — copy Memory-Grounded Review templates into a target repo.
# Idempotent: never overwrites existing files. CLAUDE.md is merged via markers.
#
# Usage: install-into-repo.sh [TARGET_REPO_DIR] [--with-ci]
#   TARGET_REPO_DIR  repo to install into (defaults to the current directory)
#   --with-ci        ALSO install the optional GitHub Actions workflows (Loop B).
#                    Off by default — local/interactive use needs no CI.
#
set -euo pipefail

# Plugin root = parent of this script's directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATES="${PLUGIN_ROOT}/templates"

# Parse args: one optional positional TARGET plus the optional --with-ci flag.
WITH_CI=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --with-ci|--with-workflows|--ci) WITH_CI=1 ;;
    -h|--help)
      echo "Usage: install-into-repo.sh [TARGET_REPO_DIR] [--with-ci]"
      echo "  --with-ci   also install the optional GitHub Actions workflows (off by default)"
      exit 0 ;;
    -*) echo "Error: unknown option: $arg" >&2; exit 1 ;;
    *)  if [ -z "$TARGET" ]; then TARGET="$arg"; else echo "Error: unexpected argument: $arg" >&2; exit 1; fi ;;
  esac
done

TARGET="${TARGET:-$(pwd)}"
if [ ! -d "$TARGET" ]; then
  echo "Error: target directory does not exist: $TARGET" >&2
  exit 1
fi
TARGET="$(cd "${TARGET}" && pwd)"
if [ ! -d "$TEMPLATES" ]; then
  echo "Error: templates directory not found at $TEMPLATES (run this from the installed plugin)." >&2
  exit 1
fi

created=()
skipped=()

# Copy a single file only if the destination does not exist.
copy_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" ]]; then
    skipped+=("${dst#"$TARGET"/}")
  else
    cp "$src" "$dst"
    created+=("${dst#"$TARGET"/}")
  fi
}

# Recursively copy a directory tree, file-by-file, never clobbering.
copy_tree() {
  local src_root="$1" dst_root="$2"
  while IFS= read -r -d '' f; do
    local rel="${f#"$src_root"/}"
    copy_file "$f" "$dst_root/$rel"
  done < <(find "$src_root" -type f ! -name '.DS_Store' ! -name 'Thumbs.db' -print0)
}

echo "Installing Memory-Grounded Review into: $TARGET"
echo "From plugin: $PLUGIN_ROOT"
echo

# 1) .claude/memory/**  (seed examples)
copy_tree "${TEMPLATES}/memory" "${TARGET}/.claude/memory"

# 2) MEMORY-STATUS.md
copy_file "${TEMPLATES}/MEMORY-STATUS.md" "${TARGET}/MEMORY-STATUS.md"

# 3) GitHub Actions workflows — OPTIONAL (Loop B). Installed only with --with-ci.
if [ "$WITH_CI" -eq 1 ]; then
  copy_file "${TEMPLATES}/workflows/pr-review.yml"     "${TARGET}/.github/workflows/pr-review.yml"
  copy_file "${TEMPLATES}/workflows/memory-update.yml" "${TARGET}/.github/workflows/memory-update.yml"
fi

# 4) CLAUDE.md — merge the marked block.
CLAUDE_TEMPLATE="${TEMPLATES}/CLAUDE.md"
CLAUDE_DST="${TARGET}/CLAUDE.md"
BEGIN="<!-- BEGIN memory-grounded-review -->"
END="<!-- END memory-grounded-review -->"

# Extract the marked block (inclusive) from the template into a temp file.
# Markers are matched as literal substrings via index() (no regex/escape surprises);
# the block is carried in a file and read with getline (no awk -v escape processing).
block_file="$(mktemp)"
trap 'rm -f "$block_file"' EXIT
awk -v b="$BEGIN" -v e="$END" '
  index($0, b) { inb = 1 }
  inb          { print }
  index($0, e) { inb = 0 }
' "$CLAUDE_TEMPLATE" > "$block_file"

if [[ ! -s "$block_file" ]]; then
  echo "Error: could not find the memory-grounded-review block markers in $CLAUDE_TEMPLATE" >&2
  exit 1
fi

if [[ ! -e "$CLAUDE_DST" ]]; then
  cp "$CLAUDE_TEMPLATE" "$CLAUDE_DST"
  created+=("CLAUDE.md")
elif grep -qF "$BEGIN" "$CLAUDE_DST"; then
  # Replace the existing marked block in place.
  tmp="$(mktemp)"
  awk -v b="$BEGIN" -v e="$END" -v bf="$block_file" '
    index($0, b) {
      while ((getline line < bf) > 0) print line
      close(bf)
      skip = 1
      next
    }
    index($0, e) { skip = 0; next }
    !skip        { print }
  ' "$CLAUDE_DST" > "$tmp"
  mv "$tmp" "$CLAUDE_DST"
  skipped+=("CLAUDE.md (memory-grounded-review block refreshed)")
else
  # Append the marked block to the existing file.
  { printf '\n'; cat "$block_file"; } >> "$CLAUDE_DST"
  skipped+=("CLAUDE.md (memory-grounded-review block appended)")
fi

echo "Created:"
if [[ ${#created[@]} -eq 0 ]]; then echo "  (nothing new)"; else printf '  + %s\n' "${created[@]}"; fi
echo
echo "Skipped (already existed):"
if [[ ${#skipped[@]} -eq 0 ]]; then echo "  (none)"; else printf '  = %s\n' "${skipped[@]}"; fi
echo
echo "Next steps:"
echo "  1. Review the seed files under .claude/memory/ — they are EXAMPLES."
echo "  2. Run  /memory-grounded-review:refresh-memory  to derive real conventions + the architecture graph."
echo "  3. Commit the result."
echo
if [ "$WITH_CI" -eq 1 ]; then
  echo "GitHub Actions (Loop B) installed. Also:"
  echo "  - Add ANTHROPIC_API_KEY (or CLAUDE_CODE_OAUTH_TOKEN) to the repo's Actions secrets."
  echo "  - Set plugin_marketplaces in .github/workflows/*.yml to your plugin repo URL."
else
  echo "GitHub Actions CI was NOT installed (local/interactive use needs none)."
  echo "  Enable it later with:  $(basename "$0") \"$TARGET\" --with-ci"
fi
