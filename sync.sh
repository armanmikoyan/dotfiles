#!/bin/bash
# Daily dotfiles sync — see README.md for how this works

DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR" || exit 1

branch=$(git branch --show-current 2>/dev/null)
[[ "$branch" != "main" ]] && exit 0

git stash 2>/dev/null
git fetch origin 2>/dev/null
git reset --hard origin/main 2>/dev/null
git stash pop 2>/dev/null

"$DOTFILES_DIR/personal/config/editor/sync.sh"

git add -A
git diff --cached --quiet && { echo "no changes"; exit 0; }

changed_dirs=$(git diff --cached --name-only | awk -F/ '{print $1}' | sort -u | paste -sd ',' -)
changed_files=$(git diff --cached --name-only | xargs -I{} basename {} | sort -u | paste -sd '-' -)
commit_msg="chore(${changed_dirs}): sync dotfiles"

branch="sync/dotfiles-${changed_files}-$(date '+%Y%m%d-%H%M%S')"
git checkout -b "$branch"
git commit -m "$commit_msg" --no-gpg-sign
git push -u origin "$branch"
git checkout main
git merge "$branch" --no-edit
echo "pushed $branch"
