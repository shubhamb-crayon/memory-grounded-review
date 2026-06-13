#!/usr/bin/env bash
#
# install-into-repo.sh — copy Repository Memory templates into a target repo.
# Idempotent: never overwrites existing files. CLAUDE.md is merged via markers.
#
# Usage: install-into-repo.sh [TARGET_REPO_DIR]   (defaults to current directory)
#
set -euo pipefail

# Plugin root = parent of this script's directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATES="${PLUGIN_ROOT}/templates"

TARGET="${1:-$(pwd)}"
TARGET="$(cd "${TARGET}" && pwd)"

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

echo "Installing Repository Memory into: $TARGET"
echo "From plugin: $PLUGIN_ROOT"
echo

# 1) .claude/memory/**  (seed examples)
copy_tree "${TEMPLATES}/memory" "${TARGET}/.claude/memory"

# 2) MEMORY-STATUS.md
copy_file "${TEMPLATES}/MEMORY-STATUS.md" "${TARGET}/MEMORY-STATUS.md"

# 3) GitHub Actions workflows
copy_file "${TEMPLATES}/workflows/pr-review.yml"    "${TARGET}/.github/workflows/pr-review.yml"
copy_file "${TEMPLATES}/workflows/memory-update.yml" "${TARGET}/.github/workflows/memory-update.yml"

# 4) CLAUDE.md — merge the marked block.
CLAUDE_TEMPLATE="${TEMPLATES}/CLAUDE.md"
CLAUDE_DST="${TARGET}/CLAUDE.md"
BEGIN="<!-- BEGIN repo-memory -->"
END="<!-- END repo-memory -->"

# Extract the marked block (inclusive) from the template.
BLOCK="$(awk -v b="$BEGIN" -v e="$END" '
  $0 ~ b {inb=1}
  inb {print}
  $0 ~ e {inb=0}
' "$CLAUDE_TEMPLATE")"

if [[ ! -e "$CLAUDE_DST" ]]; then
  cp "$CLAUDE_TEMPLATE" "$CLAUDE_DST"
  created+=("CLAUDE.md")
elif grep -qF "$BEGIN" "$CLAUDE_DST"; then
  # Replace the existing marked block in place.
  tmp="$(mktemp)"
  awk -v b="$BEGIN" -v e="$END" -v block="$BLOCK" '
    $0 ~ b {print block; skip=1; next}
    $0 ~ e {skip=0; next}
    !skip {print}
  ' "$CLAUDE_DST" > "$tmp"
  mv "$tmp" "$CLAUDE_DST"
  skipped+=("CLAUDE.md (repo-memory block refreshed)")
else
  # Append the marked block to the existing file.
  { printf '\n'; printf '%s\n' "$BLOCK"; } >> "$CLAUDE_DST"
  skipped+=("CLAUDE.md (repo-memory block appended)")
fi

echo "Created:"
if [[ ${#created[@]} -eq 0 ]]; then echo "  (nothing new)"; else printf '  + %s\n' "${created[@]}"; fi
echo
echo "Skipped (already existed):"
if [[ ${#skipped[@]} -eq 0 ]]; then echo "  (none)"; else printf '  = %s\n' "${skipped[@]}"; fi
echo
cat <<'NEXT'
Next steps:
  1. Add ANTHROPIC_API_KEY (or CLAUDE_CODE_OAUTH_TOKEN) to the repo's GitHub Actions secrets.
  2. Review the seed files under .claude/memory/ — they are EXAMPLES.
  3. Run  /repo-memory:refresh-memory  to derive real conventions + the architecture graph.
  4. Commit the result as a normal PR.
NEXT
