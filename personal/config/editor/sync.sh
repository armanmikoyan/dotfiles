#!/bin/bash
# Two-way extension sync for Cursor and VS Code — called by ~/dotfiles/sync.sh
# See README.md for how this works

DOTFILES_DIR="$HOME/dotfiles"
EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
EXT_FILE="$EDITOR_DIR/extensions.txt"
SNAPSHOT_PREFIX="$EDITOR_DIR/.extensions.snapshot"

editors=()
command -v cursor &>/dev/null && editors+=(cursor)
command -v code &>/dev/null && editors+=(code)
[[ ${#editors[@]} -eq 0 ]] && exit 0
[[ ! -f "$EXT_FILE" ]] && exit 0

<<<<<<< Updated upstream
installed=""
for cmd in "${editors[@]}"; do
  installed+=$("$cmd" --list-extensions 2>/dev/null)$'\n'
=======
# Per-editor installed lists and snapshots
declare -A installed_by snapshot_by
union_installed=""
union_snapshot=""
for cmd in "${editors[@]}"; do
  list=$("$cmd" --list-extensions 2>/dev/null | sed '/^$/d')
  installed_by[$cmd]="$list"
  union_installed+="$list"$'\n'

  snap_file="$SNAPSHOT_PREFIX.$cmd"
  snap=""
  [[ -f "$snap_file" ]] && snap=$(cat "$snap_file")
  snapshot_by[$cmd]="$snap"
  union_snapshot+="$snap"$'\n'
done
union_installed=$(echo "$union_installed" | sort -uf | sed '/^$/d')
union_snapshot=$(echo "$union_snapshot" | sort -uf | sed '/^$/d')

has() { echo "$1" | grep -qx "$2"; }

# Detect per-editor uninstalls: in snapshot for an editor but no longer installed there.
# Collect into a single list of extensions the user removed somewhere.
uninstalled=""
for cmd in "${editors[@]}"; do
  while IFS= read -r ext; do
    [[ -z "$ext" ]] && continue
    has "${installed_by[$cmd]}" "$ext" || uninstalled+="$ext"$'\n'
  done <<< "${snapshot_by[$cmd]}"
done
uninstalled=$(echo "$uninstalled" | sort -uf | sed '/^$/d')

listed=$(cat "$EXT_FILE")

# Pass 1: handle uninstalls — remove from file and uninstall from any editor that still has it
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  echo "- $ext (uninstalled)"
  if has "$listed" "$ext"; then
    grep -vx "$ext" "$EXT_FILE" > "$EXT_FILE.tmp" && mv "$EXT_FILE.tmp" "$EXT_FILE"
    listed=$(cat "$EXT_FILE")
  fi
  for cmd in "${editors[@]}"; do
    if has "${installed_by[$cmd]}" "$ext"; then
      "$cmd" --uninstall-extension "$ext" 2>/dev/null
      installed_by[$cmd]=$(echo "${installed_by[$cmd]}" | grep -vx "$ext")
    fi
  done
done <<< "$uninstalled"

# Refresh union after uninstalls
union_installed=""
for cmd in "${editors[@]}"; do
  union_installed+="${installed_by[$cmd]}"$'\n'
>>>>>>> Stashed changes
done
installed=$(echo "$installed" | sort -uf | sed '/^$/d')

<<<<<<< Updated upstream
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
=======
# Pass 2: ensure every extension in the file is installed in every editor
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  has "$uninstalled" "$ext" && continue
  for cmd in "${editors[@]}"; do
    if ! has "${installed_by[$cmd]}" "$ext"; then
      echo "+ $ext (installing in $cmd)"
>>>>>>> Stashed changes
      "$cmd" --install-extension "$ext" 2>/dev/null
    done
  fi
done <<< "$listed"

<<<<<<< Updated upstream
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  echo "$listed" | grep -q "^$ext$" && continue
=======
# Pass 3: extensions installed in any editor but missing from the file → add them
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  has "$listed" "$ext" && continue
  has "$uninstalled" "$ext" && continue
>>>>>>> Stashed changes
  echo "+ $ext (new)"
  echo "$ext" >> "$EXT_FILE"
done <<< "$installed"

sort -f -o "$EXT_FILE" "$EXT_FILE"

# Write per-editor snapshots
for cmd in "${editors[@]}"; do
  "$cmd" --list-extensions 2>/dev/null | sort -uf | sed '/^$/d' > "$SNAPSHOT_PREFIX.$cmd"
done

# Clean up old union snapshot if present
[[ -f "$SNAPSHOT_PREFIX" ]] && rm -f "$SNAPSHOT_PREFIX"
