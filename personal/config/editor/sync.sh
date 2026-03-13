#!/bin/bash
# Two-way extension sync between Cursor and extensions.txt
# Runs daily via cron — installs missing, records new, uninstalls removed
# Uses .last-sync to distinguish "newly installed in Cursor" from "removed from file"

DOTFILES_DIR="$HOME/dotfiles"
EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
EXT_FILE="$EDITOR_DIR/extensions.txt"
LAST_SYNC="$EDITOR_DIR/.last-sync"
LOG="$EDITOR_DIR/.sync.log"

exec > "$LOG" 2>&1
echo "$(date '+%Y-%m-%d %H:%M:%S') — extension sync started"


if ! command -v cursor &>/dev/null; then
  echo "cursor CLI not found, skipping"
  exit 0
fi

if [[ ! -f "$EXT_FILE" ]]; then
  echo "extensions.txt not found, skipping"
  exit 0
fi

installed=$(cursor --list-extensions 2>/dev/null)
listed=$(cat "$EXT_FILE")
last_sync=""
[[ -f "$LAST_SYNC" ]] && last_sync=$(cat "$LAST_SYNC")
changed=0
added=()
removed=()
installed_new=()

# File has it, Cursor doesn't — check last-sync to decide
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  if ! echo "$installed" | grep -q "^$ext$"; then
    if [[ -n "$last_sync" ]] && echo "$last_sync" | grep -q "^$ext$"; then
      echo "removing $ext (uninstalled from Cursor)..."
      grep -v "^$ext$" "$EXT_FILE" > "$EXT_FILE.tmp" && mv "$EXT_FILE.tmp" "$EXT_FILE"
      removed+=("$ext")
      changed=1
    else
      echo "installing $ext..."
      cursor --install-extension "$ext" 2>/dev/null
      installed_new+=("$ext")
      changed=1
    fi
  fi
done <<< "$listed"

# Cursor has it, file doesn't → newly installed in Cursor → add to file
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  if ! echo "$listed" | grep -q "^$ext$"; then
    echo "new extension: $ext"
    echo "$ext" >> "$EXT_FILE"
    added+=("$ext")
    changed=1
  fi
done <<< "$installed"

# Sort extensions.txt for clean diffs
if [[ $changed -eq 1 ]]; then
  sort -f -o "$EXT_FILE" "$EXT_FILE"
fi

# Open PR if anything changed
if [[ $changed -eq 1 ]] || ! git -C "$DOTFILES_DIR" diff --quiet -- "$EXT_FILE" 2>/dev/null; then
  cd "$DOTFILES_DIR" || exit 1

  # Build PR body with details
  pr_body="## Extension sync — $(date '+%b %d, %Y')"
  if [[ ${#added[@]} -gt 0 ]]; then
    pr_body+=$'\n\n### Added'
    for ext in "${added[@]}"; do pr_body+=$'\n'"- \`$ext\`"; done
  fi
  if [[ ${#removed[@]} -gt 0 ]]; then
    pr_body+=$'\n\n### Removed'
    for ext in "${removed[@]}"; do pr_body+=$'\n'"- \`$ext\`"; done
  fi
  if [[ ${#installed_new[@]} -gt 0 ]]; then
    pr_body+=$'\n\n### Installed on this machine'
    for ext in "${installed_new[@]}"; do pr_body+=$'\n'"- \`$ext\`"; done
  fi

  branch="sync/extensions-$(date '+%Y%m%d-%H%M%S')"
  git checkout -b "$branch"
  git add "$EXT_FILE"
  git commit -m "sync cursor extensions (auto)" --no-gpg-sign
  git push -u origin "$branch"
  git checkout main
  echo "branch $branch pushed — GitHub Actions will create the PR"
else
  echo "no changes"
fi

# Save current state for next run
cursor --list-extensions > "$LAST_SYNC" 2>/dev/null

echo "$(date '+%Y-%m-%d %H:%M:%S') — done"
