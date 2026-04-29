#!/usr/bin/env bash
# Extension sync between Cursor, VS Code, and the dotfiles repo.
# Called by ~/dotfiles/sync.sh.
#
# Files:
#   extensions.txt         - what should be installed (auto-managed; do not edit)
#   extensions.remove.txt  - extensions to uninstall (you add lines manually)
#
# Each sync run:
#   1. Process extensions.remove.txt: uninstall each listed extension from both
#      editors (if present), remove from extensions.txt, then truncate the file.
#   2. Detect newly-installed extensions in either editor -> add to extensions.txt.
#   3. Install every extension listed in extensions.txt into any editor missing it
#      (covers fresh-machine setup and cross-editor propagation).
#
# Note: Uninstalling directly from an editor (without using extensions.remove.txt)
# is ignored. Use extensions.remove.txt if you want the removal to propagate.

DOTFILES_DIR="$HOME/dotfiles"
EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
EXT_FILE="$EDITOR_DIR/extensions.txt"
REMOVE_FILE="$EDITOR_DIR/extensions.remove.txt"

editors=()
command -v cursor >/dev/null 2>&1 && editors+=(cursor)
command -v code >/dev/null 2>&1 && editors+=(code)
[ "${#editors[@]}" -eq 0 ] && exit 0
[ ! -f "$EXT_FILE" ] && touch "$EXT_FILE"
[ ! -f "$REMOVE_FILE" ] && touch "$REMOVE_FILE"

tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

for cmd in "${editors[@]}"; do
  "$cmd" --list-extensions 2>/dev/null | sed '/^$/d' | sort -fu > "$tmp/installed.$cmd"
done

sed '/^$/d' "$EXT_FILE" | sort -fu > "$tmp/listed"
sed '/^$/d' "$REMOVE_FILE" | sort -fu > "$tmp/remove"

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
    grep -vxF "$ext" "$tmp/listed" > "$tmp/listed.new" || true
    mv "$tmp/listed.new" "$tmp/listed"
  done < "$tmp/remove"
  : > "$REMOVE_FILE"
fi

: > "$tmp/all_installed"
for cmd in "${editors[@]}"; do
  cat "$tmp/installed.$cmd" >> "$tmp/all_installed"
done
sort -fu -o "$tmp/all_installed" "$tmp/all_installed"

comm -23 "$tmp/all_installed" "$tmp/listed" > "$tmp/new"
if [ -s "$tmp/remove" ]; then
  comm -23 "$tmp/new" "$tmp/remove" > "$tmp/new.filtered"
  mv "$tmp/new.filtered" "$tmp/new"
fi

if [ -s "$tmp/new" ]; then
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    echo "+ $ext (new, adding to extensions.txt)"
    echo "$ext" >> "$tmp/listed"
  done < "$tmp/new"
  sort -fu -o "$tmp/listed" "$tmp/listed"
fi

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

exit 0
