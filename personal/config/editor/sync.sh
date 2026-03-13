#!/bin/bash
# Two-way extension sync between Cursor and extensions.txt
# Runs daily via cron — installs missing, records new, uninstalls removed
# Uses .last-sync to distinguish "newly installed" from "removed from file"
# Pushes a sync/ branch; GitHub Actions creates the PR

DOTFILES_DIR="$HOME/dotfiles"
EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
EXT_FILE="$EDITOR_DIR/extensions.txt"
LAST_SYNC="$EDITOR_DIR/.last-sync"

cd "$DOTFILES_DIR" && git checkout main 2>/dev/null && git pull 2>/dev/null

if ! command -v cursor &>/dev/null; then
  echo "cursor CLI not found, skipping"
  exit 0
fi

[[ ! -f "$EXT_FILE" ]] && echo "extensions.txt not found" && exit 0

installed=$(cursor --list-extensions 2>/dev/null)
listed=$(cat "$EXT_FILE")
last_sync=""
[[ -f "$LAST_SYNC" ]] && last_sync=$(cat "$LAST_SYNC")

changed=0
added=()
removed=()
installed_on_machine=()

# File has it, Cursor doesn't
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  echo "$installed" | grep -q "^$ext$" && continue

  if [[ -n "$last_sync" ]] && echo "$last_sync" | grep -q "^$ext$"; then
    echo "- $ext (uninstalled from Cursor)"
    grep -v "^$ext$" "$EXT_FILE" > "$EXT_FILE.tmp" && mv "$EXT_FILE.tmp" "$EXT_FILE"
    removed+=("$ext")
  else
    echo "+ $ext (installing)"
    cursor --install-extension "$ext" 2>/dev/null
    installed_on_machine+=("$ext")
  fi
  changed=1
done <<< "$listed"

# Cursor has it, file doesn't
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  echo "$listed" | grep -q "^$ext$" && continue

  echo "+ $ext (new in Cursor)"
  echo "$ext" >> "$EXT_FILE"
  added+=("$ext")
  changed=1
done <<< "$installed"

[[ $changed -eq 1 ]] && sort -f -o "$EXT_FILE" "$EXT_FILE"

# Push branch if anything changed (GitHub Actions creates the PR)
if [[ $changed -eq 1 ]] || ! git -C "$DOTFILES_DIR" diff --quiet -- "$EXT_FILE" 2>/dev/null; then
  pr_body="## Extension sync — $(date '+%b %d, %Y')"
  [[ ${#added[@]} -gt 0 ]]                && { pr_body+=$'\n\n### Added';                for e in "${added[@]}"; do pr_body+=$'\n'"- \`$e\`"; done; }
  [[ ${#removed[@]} -gt 0 ]]              && { pr_body+=$'\n\n### Removed';              for e in "${removed[@]}"; do pr_body+=$'\n'"- \`$e\`"; done; }
  [[ ${#installed_on_machine[@]} -gt 0 ]] && { pr_body+=$'\n\n### Installed on machine'; for e in "${installed_on_machine[@]}"; do pr_body+=$'\n'"- \`$e\`"; done; }

  branch="sync/extensions-$(date '+%Y%m%d-%H%M%S')"
  git checkout -b "$branch"
  git add "$EXT_FILE"
  git commit -m "sync cursor extensions" --no-gpg-sign
  git push -u origin "$branch"
  git checkout main
  echo "pushed $branch"
else
  echo "no changes"
fi

cursor --list-extensions > "$LAST_SYNC" 2>/dev/null
