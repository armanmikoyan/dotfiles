#!/bin/bash
# Daily dotfiles sync — see README.md for how this works

DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR" || exit 1

branch=$(git branch --show-current 2>/dev/null)
[[ "$branch" != "main" ]] && exit 0

# Only stash if there are uncommitted changes (tracked or untracked).
# Use a uniquely-tagged stash and pop by ref so we never apply someone else's old stash.
stash_tag="auto-sync-$$-$(date +%s)"
stash_ref=""
if ! git diff --quiet || ! git diff --cached --quiet || [[ -n $(git ls-files --others --exclude-standard) ]]; then
  if git stash push -u -m "$stash_tag" >/dev/null 2>&1; then
    stash_ref=$(git stash list --format='%gd %s' | grep -F "$stash_tag" | head -n1 | awk '{print $1}')
  fi
fi

git fetch origin 2>/dev/null
git reset --hard origin/main 2>/dev/null

if [[ -n "$stash_ref" ]]; then
  if ! git stash pop "$stash_ref" 2>/dev/null; then
    echo "sync: stash pop conflict on $stash_ref — aborting before any commit"
    echo "      resolve manually with: git status; git stash list"
    exit 1
  fi
fi

# Refuse to proceed if any tracked file ended up with conflict markers
if git grep -lE '^(<<<<<<<|=======|>>>>>>>)( |$)' 2>/dev/null | grep -q .; then
  echo "sync: conflict markers detected — aborting before any commit"
  exit 1
fi

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
