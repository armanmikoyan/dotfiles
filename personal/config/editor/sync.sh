#!/usr/bin/env bash
# Extension sync between Cursor, VS Code, and the dotfiles repo.
# Called by ~/dotfiles/sync.sh.
#
# Source of truth: extensions.txt
#   eamodio.gitlens                  - kept installed in both editors
#   xabikos.javascriptsnippets # remove   - uninstall from both editors and drop this line
#
# Each sync run:
#   1. Process lines marked '# remove': uninstall from both editors, then delete the line.
#   2. Detect newly-installed extensions in either editor -> append to extensions.txt.
#   3. Install every listed (un-marked) extension into any editor missing it.
#      Extensions not in an editor's marketplace are silently skipped for that editor.

DOTFILES_DIR="$HOME/dotfiles"
EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
EXT_FILE="$EDITOR_DIR/extensions.txt"

editors=()
command -v cursor >/dev/null 2>&1 && editors+=(cursor)
command -v code >/dev/null 2>&1 && editors+=(code)
[ "${#editors[@]}" -eq 0 ] && exit 0
[ ! -f "$EXT_FILE" ] && touch "$EXT_FILE"

tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

for cmd in "${editors[@]}"; do
  "$cmd" --list-extensions 2>/dev/null | sed '/^$/d' | sort -fu > "$tmp/installed.$cmd"
done

# Parse extensions.txt into two lists: keep and remove.
# Strip comments/whitespace; if the trailing comment matches '# *remove*' (case-insensitive)
# the extension is queued for removal.
: > "$tmp/keep"
: > "$tmp/remove"
while IFS= read -r line || [ -n "$line" ]; do
  trimmed=$(echo "$line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
  [ -z "$trimmed" ] && continue
  case "$trimmed" in \#*) continue ;; esac
  ext=$(echo "$trimmed" | sed -E 's/[[:space:]]*#.*$//' | sed -E 's/[[:space:]]+$//')
  comment=$(echo "$trimmed" | sed -nE 's/^[^#]*#[[:space:]]*//p')
  [ -z "$ext" ] && continue
  if echo "$comment" | grep -qiE '(^|[^a-z])remove([^a-z]|$)'; then
    echo "$ext" >> "$tmp/remove"
  else
    echo "$ext" >> "$tmp/keep"
  fi
done < "$EXT_FILE"
sort -fu -o "$tmp/keep" "$tmp/keep"
sort -fu -o "$tmp/remove" "$tmp/remove"

# Pass 1: process removals.
if [ -s "$tmp/remove" ]; then
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    echo "- $ext (removing)"
    for cmd in "${editors[@]}"; do
      if grep -qxF "$ext" "$tmp/installed.$cmd"; then
        "$cmd" --uninstall-extension "$ext" >/dev/null 2>&1
        grep -vxF "$ext" "$tmp/installed.$cmd" > "$tmp/installed.$cmd.new" || true
        mv "$tmp/installed.$cmd.new" "$tmp/installed.$cmd"
      fi
    done
    grep -vxF "$ext" "$tmp/keep" > "$tmp/keep.new" || true
    mv "$tmp/keep.new" "$tmp/keep"
  done < "$tmp/remove"
fi

# Pass 2: detect newly-installed extensions in any editor (skip ones queued for removal).
: > "$tmp/all_installed"
for cmd in "${editors[@]}"; do
  cat "$tmp/installed.$cmd" >> "$tmp/all_installed"
done
sort -fu -o "$tmp/all_installed" "$tmp/all_installed"

comm -23 "$tmp/all_installed" "$tmp/keep" > "$tmp/new"
if [ -s "$tmp/remove" ]; then
  comm -23 "$tmp/new" "$tmp/remove" > "$tmp/new.filtered"
  mv "$tmp/new.filtered" "$tmp/new"
fi

if [ -s "$tmp/new" ]; then
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    echo "+ $ext (new, adding to extensions.txt)"
    echo "$ext" >> "$tmp/keep"
  done < "$tmp/new"
  sort -fu -o "$tmp/keep" "$tmp/keep"
fi

# Pass 3: install missing kept extensions; silently skip marketplace mismatches.
while IFS= read -r ext; do
  [ -z "$ext" ] && continue
  for cmd in "${editors[@]}"; do
    grep -qxF "$ext" "$tmp/installed.$cmd" && continue
    out=$("$cmd" --install-extension "$ext" 2>&1)
    if echo "$out" | grep -qiE "not found|is not in the marketplace|failed installing"; then
      continue
    fi
    echo "+ $ext (installed in $cmd)"
    echo "$ext" >> "$tmp/installed.$cmd"
    sort -fu -o "$tmp/installed.$cmd" "$tmp/installed.$cmd"
  done
done < "$tmp/keep"

cp "$tmp/keep" "$EXT_FILE"

exit 0
