#!/bin/bash
# Daily dotfiles sync — extensions + any other changes
# Pushes a sync/ branch; GitHub Actions creates the PR

DOTFILES_DIR="$HOME/dotfiles"
EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
EXT_FILE="$EDITOR_DIR/extensions.txt"
LAST_SYNC="$EDITOR_DIR/.last-sync"

cd "$DOTFILES_DIR" || exit 1

branch=$(git branch --show-current 2>/dev/null)
[[ "$branch" != "main" ]] && exit 0

git pull 2>/dev/null

# ── Extension sync ───────────────────────────────────────
if command -v cursor &>/dev/null && [[ -f "$EXT_FILE" ]]; then
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
fi

# ── Commit & push ────────────────────────────────────────
git add -A
git diff --cached --quiet && { echo "no changes"; exit 0; }

# Build conventional commit message from changed folders
changed_dirs=$(git diff --cached --name-only | awk -F/ '{print $1}' | sort -u | paste -sd ',' -)
commit_msg="chore(${changed_dirs}): sync dotfiles"

branch="sync/dotfiles-$(date '+%Y%m%d-%H%M%S')"
git checkout -b "$branch"
git commit -m "$commit_msg" --no-gpg-sign
git push -u origin "$branch"
git checkout main
echo "pushed $branch"
