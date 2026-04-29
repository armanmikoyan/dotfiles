#!/usr/bin/env bash
# Two-way extension sync between Cursor and VS Code (and extensions.txt).
# Called by ~/dotfiles/sync.sh.
#
# Behavior:
#   - Install in editor A only      → next sync installs in editor B, adds to file.
#   - Uninstall from editor A       → next sync uninstalls from editor B, removes from file.
#   - File has it, editor missing it → install (covers fresh-machine setup).
#
# Per-editor snapshots (.extensions.snapshot.<editor>, gitignored) record what
# was installed at the end of the last sync, so we can distinguish a user
# uninstall (was in snapshot, not now) from never-installed.

DOTFILES_DIR="$HOME/dotfiles"
EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
EXT_FILE="$EDITOR_DIR/extensions.txt"
SNAPSHOT_PREFIX="$EDITOR_DIR/.extensions.snapshot"

editors=()
command -v cursor >/dev/null 2>&1 && editors+=(cursor)
command -v code >/dev/null 2>&1 && editors+=(code)
[ "${#editors[@]}" -eq 0 ] && exit 0
[ ! -f "$EXT_FILE" ] && touch "$EXT_FILE"

tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

# Collect current installed lists and snapshots into temp files.
for cmd in "${editors[@]}"; do
  "$cmd" --list-extensions 2>/dev/null | sed '/^$/d' | sort -fu > "$tmp/installed.$cmd"
  snap_file="$SNAPSHOT_PREFIX.$cmd"
  if [ -f "$snap_file" ]; then
    sed '/^$/d' "$snap_file" | sort -fu > "$tmp/snapshot.$cmd"
  else
    : > "$tmp/snapshot.$cmd"
  fi
done

sed '/^$/d' "$EXT_FILE" | sort -fu > "$tmp/listed"

# Detect uninstalls: lines in any editor's snapshot but not in its current installed list.
: > "$tmp/uninstalled"
for cmd in "${editors[@]}"; do
  comm -23 "$tmp/snapshot.$cmd" "$tmp/installed.$cmd" >> "$tmp/uninstalled"
done
sort -fu -o "$tmp/uninstalled" "$tmp/uninstalled"

# Apply uninstalls: remove from listed, uninstall from any editor that still has it.
if [ -s "$tmp/uninstalled" ]; then
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    echo "- $ext (uninstalled, propagating)"
    for cmd in "${editors[@]}"; do
      if grep -qxF "$ext" "$tmp/installed.$cmd"; then
        "$cmd" --uninstall-extension "$ext" >/dev/null 2>&1
        grep -vxF "$ext" "$tmp/installed.$cmd" > "$tmp/installed.$cmd.new" || true
        mv "$tmp/installed.$cmd.new" "$tmp/installed.$cmd"
      fi
    done
    grep -vxF "$ext" "$tmp/listed" > "$tmp/listed.new" || true
    mv "$tmp/listed.new" "$tmp/listed"
  done < "$tmp/uninstalled"
fi

# Detect new installs: in current but not in own snapshot, and not just-uninstalled.
: > "$tmp/new_installs"
for cmd in "${editors[@]}"; do
  comm -23 "$tmp/installed.$cmd" "$tmp/snapshot.$cmd" >> "$tmp/new_installs"
done
sort -fu -o "$tmp/new_installs" "$tmp/new_installs"
comm -23 "$tmp/new_installs" "$tmp/uninstalled" > "$tmp/new_installs.filtered"
mv "$tmp/new_installs.filtered" "$tmp/new_installs"

# Add newly-installed extensions to the listed set.
if [ -s "$tmp/new_installs" ]; then
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    if ! grep -qxF "$ext" "$tmp/listed"; then
      echo "+ $ext (new, adding to extensions.txt)"
      echo "$ext" >> "$tmp/listed"
    fi
  done < "$tmp/new_installs"
  sort -fu -o "$tmp/listed" "$tmp/listed"
fi

# Ensure every listed extension is installed in every editor.
while IFS= read -r ext; do
  [ -z "$ext" ] && continue
  for cmd in "${editors[@]}"; do
    if ! grep -qxF "$ext" "$tmp/installed.$cmd"; then
      echo "+ $ext (installing in $cmd)"
      "$cmd" --install-extension "$ext" >/dev/null 2>&1
      echo "$ext" >> "$tmp/installed.$cmd"
      sort -fu -o "$tmp/installed.$cmd" "$tmp/installed.$cmd"
    fi
  done
done < "$tmp/listed"

cp "$tmp/listed" "$EXT_FILE"

# Refresh per-editor snapshots from current state on disk.
for cmd in "${editors[@]}"; do
  "$cmd" --list-extensions 2>/dev/null | sed '/^$/d' | sort -fu > "$SNAPSHOT_PREFIX.$cmd"
done

# Remove obsolete union snapshot file from older script versions.
[ -f "$SNAPSHOT_PREFIX" ] && rm -f "$SNAPSHOT_PREFIX"

exit 0
