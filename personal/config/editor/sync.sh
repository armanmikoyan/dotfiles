#!/usr/bin/env bash
# Extension sync between Cursor, VS Code, Antigravity IDE, and the dotfiles repo.
# Called by ~/dotfiles/sync.sh.
#
# Source of truth: extensions.txt
#   eamodio.gitlens                  - keep installed in both editors
#   svelte.svelte-vscode # remove    - uninstall from both editors
#
# Each sync run:
#   1. Uninstall every "# remove" extension from any editor that still has it.
#      If a dependency blocks the uninstall, prints a clear "blocked by X"
#      message so you can mark the blocker too. Cascade-uninstalls in deps order
#      automatically when both blocker and blocked are marked.
#   2. Install every plain extension into any editor missing it.
#      Marketplace mismatches (e.g. anysphere.* in VS Code) are silently skipped.
#   3. For each "# remove" extension that is no longer installed in any editor,
#      drop its line from extensions.txt. Lines blocked by deps stay so future
#      runs keep retrying.
#   4. Auto-detect any extension installed in either editor that isn't already
#      in extensions.txt and append it as a new line.

DOTFILES_DIR="$HOME/dotfiles"
EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
EXT_FILE="$EDITOR_DIR/extensions.txt"

editors=()
command -v cursor >/dev/null 2>&1 && editors+=(cursor)
command -v code >/dev/null 2>&1 && editors+=(code)
# Antigravity IDE bundles the same CLI surface as VS Code; app bin is not on PATH by default.
if [[ -x "/Applications/Antigravity IDE.app/Contents/Resources/app/bin/antigravity-ide" ]]; then
  PATH="/Applications/Antigravity IDE.app/Contents/Resources/app/bin:$PATH"
fi
command -v antigravity-ide >/dev/null 2>&1 && editors+=(antigravity-ide)
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

try_uninstall() {
  cmd=$1; ext=$2
  out=$("$cmd" --uninstall-extension "$ext" 2>&1)
  rc=$?
  if [ $rc -eq 0 ] && ! printf '%s' "$out" | grep -qiE 'cannot uninstall|is not installed'; then
    echo "- $ext (uninstalled from $cmd)"
    grep -vxF "$ext" "$tmp/installed.$cmd" > "$tmp/installed.$cmd.new" || true
    mv "$tmp/installed.$cmd.new" "$tmp/installed.$cmd"
    return 0
  fi
  if printf '%s' "$out" | grep -qi 'is not installed'; then
    grep -vxF "$ext" "$tmp/installed.$cmd" > "$tmp/installed.$cmd.new" || true
    mv "$tmp/installed.$cmd.new" "$tmp/installed.$cmd"
    return 0
  fi
  blocker=$(printf '%s' "$out" | sed -nE "s/.*'([^']+)' extension depends on this.*/\1/p" | head -n1)
  printf '%s\n' "$blocker" > "$tmp/last_blocker"
  return 1
}

if [ -s "$tmp/remove_ids" ]; then
  for cmd in "${editors[@]}"; do
    progress=1
    while [ $progress -eq 1 ]; do
      progress=0
      while IFS= read -r ext; do
        [ -z "$ext" ] && continue
        grep -qxF "$ext" "$tmp/installed.$cmd" || continue
        if try_uninstall "$cmd" "$ext"; then
          progress=1
        fi
      done < "$tmp/remove_ids"
    done

    while IFS= read -r ext; do
      [ -z "$ext" ] && continue
      grep -qxF "$ext" "$tmp/installed.$cmd" || continue
      out=$("$cmd" --uninstall-extension "$ext" 2>&1)
      blocker=$(printf '%s' "$out" | sed -nE "s/.*'([^']+)' extension depends on this.*/\1/p" | head -n1)
      if [ -n "$blocker" ]; then
        echo "! $ext (cannot uninstall from $cmd; blocked by '$blocker' — mark its line with # remove too)"
      else
        msg=$(printf '%s' "$out" | grep -iE 'cannot|error|failed' | head -n1)
        echo "! $ext (uninstall from $cmd failed: ${msg:-unknown})"
      fi
    done < "$tmp/remove_ids"
  done
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

: > "$tmp/union_installed"
for cmd in "${editors[@]}"; do
  cat "$tmp/installed.$cmd" >> "$tmp/union_installed"
done
sort -fu -o "$tmp/union_installed" "$tmp/union_installed"

: > "$tmp/drop_ids"
if [ -s "$tmp/remove_ids" ]; then
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    grep -qxF "$ext" "$tmp/union_installed" && continue
    printf '%s\n' "$ext" >> "$tmp/drop_ids"
  done < "$tmp/remove_ids"
fi

if [ -s "$tmp/drop_ids" ]; then
  cp "$EXT_FILE" "$tmp/ext.orig"
  : > "$tmp/ext.new"
  while IFS= read -r line || [ -n "$line" ]; do
    raw="$line"
    trimmed=${line%$'\r'}
    trimmed=$(printf '%s' "$trimmed" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
    if [ -z "$trimmed" ] || case "$trimmed" in \#*) true ;; *) false ;; esac; then
      printf '%s\n' "$raw" >> "$tmp/ext.new"
      continue
    fi
    ext_id=$(printf '%s' "$trimmed" | sed -E 's/[[:space:]]*#.*$//' | sed -E 's/[[:space:]]+$//')
    if grep -qxF "$ext_id" "$tmp/drop_ids"; then
      echo "  $ext_id (dropping line from extensions.txt — fully uninstalled)"
      continue
    fi
    printf '%s\n' "$raw" >> "$tmp/ext.new"
  done < "$tmp/ext.orig"
  mv "$tmp/ext.new" "$EXT_FILE"
  comm -23 "$tmp/remove_ids" "$tmp/drop_ids" > "$tmp/remove_ids.new"
  mv "$tmp/remove_ids.new" "$tmp/remove_ids"
fi

cat "$tmp/install_ids" "$tmp/remove_ids" 2>/dev/null | sort -fu > "$tmp/known_ids"

comm -23 "$tmp/union_installed" "$tmp/known_ids" > "$tmp/new_ids"

if [ -s "$tmp/new_ids" ]; then
  if [ -s "$EXT_FILE" ] && [ "$(tail -c 1 "$EXT_FILE" | xxd -p)" != "0a" ]; then
    printf '\n' >> "$EXT_FILE"
  fi
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    echo "+ $ext (new, appending to extensions.txt)"
    printf '%s\n' "$ext" >> "$EXT_FILE"
    for cmd in "${editors[@]}"; do
      grep -qxF "$ext" "$tmp/installed.$cmd" && continue
      out=$("$cmd" --install-extension "$ext" 2>&1)
      if printf '%s' "$out" | grep -qiE "not found|is not in the marketplace|failed installing"; then
        continue
      fi
      echo "+ $ext (installed in $cmd)"
      printf '%s\n' "$ext" >> "$tmp/installed.$cmd"
      sort -fu -o "$tmp/installed.$cmd" "$tmp/installed.$cmd"
    done
  done < "$tmp/new_ids"
fi

exit 0
