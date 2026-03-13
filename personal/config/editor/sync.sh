#!/bin/bash
# Two-way extension sync between Cursor and extensions.txt
# Called by ~/dotfiles/sync.sh before the general commit

DOTFILES_DIR="$HOME/dotfiles"
EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
EXT_FILE="$EDITOR_DIR/extensions.txt"
LAST_SYNC="$EDITOR_DIR/.last-sync"

command -v cursor &>/dev/null || exit 0
[[ ! -f "$EXT_FILE" ]] && exit 0

installed=$(cursor --list-extensions 2>/dev/null)
listed=$(cat "$EXT_FILE")
last_sync=""
[[ -f "$LAST_SYNC" ]] && last_sync=$(cat "$LAST_SYNC")

# File has it, Cursor doesn't
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  echo "$installed" | grep -q "^$ext$" && continue

  if [[ -n "$last_sync" ]] && echo "$last_sync" | grep -q "^$ext$"; then
    echo "- $ext (uninstalled from Cursor)"
    grep -v "^$ext$" "$EXT_FILE" > "$EXT_FILE.tmp" && mv "$EXT_FILE.tmp" "$EXT_FILE"
  else
    echo "+ $ext (installing)"
    cursor --install-extension "$ext" 2>/dev/null
  fi
done <<< "$listed"

# Cursor has it, file doesn't
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  echo "$listed" | grep -q "^$ext$" && continue
  echo "+ $ext (new in Cursor)"
  echo "$ext" >> "$EXT_FILE"
done <<< "$installed"

sort -f -o "$EXT_FILE" "$EXT_FILE"
cursor --list-extensions > "$LAST_SYNC" 2>/dev/null


asasasassa