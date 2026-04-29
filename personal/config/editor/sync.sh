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

# Per-editor installed lists (newline-separated, no blanks)
declare -A installed_by
union_installed=""
for cmd in "${editors[@]}"; do
  list=$("$cmd" --list-extensions 2>/dev/null | sed '/^$/d')
  installed_by[$cmd]="$list"
  union_installed+="$list"$'\n'
done
union_installed=$(echo "$union_installed" | sort -uf | sed '/^$/d')

listed=$(cat "$EXT_FILE")
last_sync=""
[[ -f "$LAST_SYNC" ]] && last_sync=$(cat "$LAST_SYNC")

# Pass 1: for each extension in the file, ensure it's installed in EVERY editor
# (or remove it from the file if it was uninstalled from all editors since last sync)
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue

  in_union=false
  echo "$union_installed" | grep -qx "$ext" && in_union=true

  if ! $in_union && [[ -n "$last_sync" ]] && echo "$last_sync" | grep -qx "$ext"; then
    echo "- $ext (uninstalled)"
    grep -vx "$ext" "$EXT_FILE" > "$EXT_FILE.tmp" && mv "$EXT_FILE.tmp" "$EXT_FILE"
    continue
  fi

  for cmd in "${editors[@]}"; do
    if ! echo "${installed_by[$cmd]}" | grep -qx "$ext"; then
      echo "+ $ext (installing in $cmd)"
      "$cmd" --install-extension "$ext" 2>/dev/null
    fi
  done
done <<< "$listed"

# Pass 2: extensions installed in any editor but missing from the file → add them
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  echo "$listed" | grep -qx "$ext" && continue
  echo "+ $ext (new)"
  echo "$ext" >> "$EXT_FILE"
done <<< "$union_installed"

sort -f -o "$EXT_FILE" "$EXT_FILE"

snapshot=""
for cmd in "${editors[@]}"; do
  snapshot+=$("$cmd" --list-extensions 2>/dev/null)$'\n'
done
echo "$snapshot" | sort -uf | sed '/^$/d' > "$LAST_SYNC"
