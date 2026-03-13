#!/bin/bash
# ── Extension Sync ───────────────────────────────────────
# Two-way sync between Cursor editor and extensions.txt
# Called by ~/dotfiles/sync.sh before the general commit
#
# How it works:
#   1. Compares Cursor's installed extensions against extensions.txt
#   2. If Cursor is missing an extension from the file → installs it
#   3. If Cursor has a new extension not in the file → adds it
#   4. If an extension was uninstalled via Cursor UI → removes it from file
#
# How uninstall detection works:
#   .last-sync stores what Cursor had at the end of the last sync.
#   If extensions.txt has it, but Cursor doesn't, and .last-sync had it,
#   that means it was removed via Cursor UI → remove from file.
#   If .last-sync didn't have it, it's a new entry (e.g. new machine) → install it.
#
# extensions.txt:
#   DO NOT edit manually. Use Cursor's UI to install/uninstall.
#   If you delete the file, sync recreates it from Cursor's extensions.
#
# .extensions.snapshot:
#   DO NOT edit. If deleted, sync can't detect uninstalls —
#   it will reinstall everything from extensions.txt instead.
#   The file is recreated automatically on the next run.

DOTFILES_DIR="$HOME/dotfiles"
EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
EXT_FILE="$EDITOR_DIR/extensions.txt"
LAST_SYNC="$EDITOR_DIR/.extensions.snapshot"

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
