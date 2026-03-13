#!/bin/bash
# Daily dotfiles sync — extensions + any other changes
# Pushes a sync/ branch; GitHub Actions creates the PR
# Remote is source of truth — rejected PRs are discarded on next sync

DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR" || exit 1

branch=$(git branch --show-current 2>/dev/null)
[[ "$branch" != "main" ]] && exit 0

# Save local changes, reset to remote (source of truth), re-apply
git stash 2>/dev/null
git fetch origin 2>/dev/null
git reset --hard origin/main 2>/dev/null
git stash pop 2>/dev/null

# Extension sync
"$DOTFILES_DIR/personal/config/editor/sync.sh"

# Commit & push
git add -A
git diff --cached --quiet && { echo "no changes"; exit 0; }

changed_dirs=$(git diff --cached --name-only | awk -F/ '{print $1}' | sort -u | paste -sd ',' -)
commit_msg="chore(${changed_dirs}): sync dotfiles"

branch="sync/dotfiles-$(date '+%Y%m%d-%H%M%S')"
git checkout -b "$branch"
git commit -m "$commit_msg" --no-gpg-sign
git push -u origin "$branch"
git checkout main
git merge "$branch" --no-edit
echo "pushed $branch"
