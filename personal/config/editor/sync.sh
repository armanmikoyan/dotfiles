#!/usr/bin/env bash
# Extension sync between Cursor, VS Code, and the dotfiles repo.
# Called by ~/dotfiles/sync.sh.
#
# Source of truth: extensions.txt
#   eamodio.gitlens                  - keep installed in both editors
#   svelte.svelte-vscode # remove    - keep uninstalled in both editors
#                                      (line is permanent; protects against
#                                       dependency-pulled re-installs)
#
# Each sync run:
#   1. Uninstall every "# remove" extension from any editor that still has it.
#   2. Install every plain extension into any editor missing it.
#      Marketplace mismatches (e.g. anysphere.* in VS Code) are silently skipped.
#   3. Auto-detect any extension installed in either editor that isn't already
#      in extensions.txt and append it as a new line. "# remove" lines are
#      preserved across runs and never re-added.

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

snapshot_installed() {
  for cmd in "${editors[@]}"; do
    "$cmd" --list-extensions 2>/dev/null | sed '/^$/d' | sort -fu > "$tmp/installed.$cmd"
  done
}

snapshot_installed

: > "$tmp/install_ids"
: > "$tmp/remove_ids"
while IFS= read -r line || [ -n "$line" ]; do
  trimmed=${line%$'\r'}
  trimmed=$(printf '%s' "$trimmed" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
  [ -z "$trimmed" ] && continue
  case "$trimmed" in \#*) continue ;; esac

  ext=$(printf '%s' "$trimmed" | sed -E 's/[[:space:]]*#.*$//' | sed -E 's/[[:space:]]+$//')
  rest=$(printf '%s' "$trimmed" | sed -nE 's/^[^#]*#[[:space:]]*(.*)$/\1/p')
  [ -z "$ext" ] && continue

  if printf '%s' "$rest" | grep -qiE '(^|[^a-z])remove([^a-z]|$)'; then
    printf '%s\n' "$ext" >> "$tmp/remove_ids"
  else
    printf '%s\n' "$ext" >> "$tmp/install_ids"
  fi
done < "$EXT_FILE"
sort -fu -o "$tmp/install_ids" "$tmp/install_ids"
sort -fu -o "$tmp/remove_ids" "$tmp/remove_ids"

if [ -s "$tmp/remove_ids" ]; then
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    for cmd in "${editors[@]}"; do
      grep -qxF "$ext" "$tmp/installed.$cmd" || continue
      "$cmd" --uninstall-extension "$ext" >/dev/null 2>&1
      echo "- $ext (uninstalled from $cmd)"
    done
  done < "$tmp/remove_ids"
fi

if [ -s "$tmp/install_ids" ]; then
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    for cmd in "${editors[@]}"; do
      grep -qxF "$ext" "$tmp/installed.$cmd" && continue
      out=$("$cmd" --install-extension "$ext" 2>&1)
      if printf '%s' "$out" | grep -qiE "not found|is not in the marketplace|failed installing"; then
        continue
      fi
      echo "+ $ext (installed in $cmd)"
    done
  done < "$tmp/install_ids"
fi

snapshot_installed

cat "$tmp/install_ids" "$tmp/remove_ids" 2>/dev/null | sort -fu > "$tmp/known_ids"

: > "$tmp/union_installed"
for cmd in "${editors[@]}"; do
  cat "$tmp/installed.$cmd" >> "$tmp/union_installed"
done
sort -fu -o "$tmp/union_installed" "$tmp/union_installed"

comm -23 "$tmp/union_installed" "$tmp/known_ids" > "$tmp/new_ids"

if [ -s "$tmp/new_ids" ]; then
  if [ -s "$EXT_FILE" ] && [ "$(tail -c 1 "$EXT_FILE" | xxd -p)" != "0a" ]; then
    printf '\n' >> "$EXT_FILE"
  fi
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    echo "+ $ext (new, appending to extensions.txt)"
    printf '%s\n' "$ext" >> "$EXT_FILE"
  done < "$tmp/new_ids"
fi

exit 0
