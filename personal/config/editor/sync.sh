#!/bin/bash
# Two-way extension sync for Cursor and VS Code — called by ~/dotfiles/sync.sh
# See README.md for how this works

DOTFILES_DIR="$HOME/dotfiles"
EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
EXT_FILE="$EDITOR_DIR/extensions.txt"
LAST_SYNC="$EDITOR_DIR/.extensions.snapshot"

editors=()
command -v cursor &>/dev/null && editors+=(cursor)
command -v code &>/dev/null && editors+=(code)
[[ ${#editors[@]} -eq 0 ]] && exit 0
[[ ! -f "$EXT_FILE" ]] && exit 0

installed=""
for cmd in "${editors[@]}"; do
  installed+=$("$cmd" --list-extensions 2>/dev/null)$'\n'
done
installed=$(echo "$installed" | sort -uf | sed '/^$/d')

listed=$(cat "$EXT_FILE")
last_sync=""
[[ -f "$LAST_SYNC" ]] && last_sync=$(cat "$LAST_SYNC")

while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  echo "$installed" | grep -q "^$ext$" && continue

  if [[ -n "$last_sync" ]] && echo "$last_sync" | grep -q "^$ext$"; then
    echo "- $ext (uninstalled)"
    grep -v "^$ext$" "$EXT_FILE" > "$EXT_FILE.tmp" && mv "$EXT_FILE.tmp" "$EXT_FILE"
  else
    echo "+ $ext (installing)"
    for cmd in "${editors[@]}"; do
      "$cmd" --install-extension "$ext" 2>/dev/null
    done
  fi
done <<< "$listed"

while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  echo "$listed" | grep -q "^$ext$" && continue
  echo "+ $ext (new)"
  echo "$ext" >> "$EXT_FILE"
done <<< "$installed"

sort -f -o "$EXT_FILE" "$EXT_FILE"

snapshot=""
for cmd in "${editors[@]}"; do
  snapshot+=$("$cmd" --list-extensions 2>/dev/null)$'\n'
done
echo "$snapshot" | sort -uf | sed '/^$/d' > "$LAST_SYNC"
