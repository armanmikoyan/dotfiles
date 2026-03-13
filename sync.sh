#!/bin/bash
# ── Dotfiles Sync ────────────────────────────────────────
# Runs daily via cron (or manually: sync alias)
# Syncs everything in ~/dotfiles and opens a PR for review
#
# How it works:
#   1. Stash local changes to preserve uncommitted edits
#   2. Reset local main to match remote (remote is source of truth)
#   3. Re-apply stashed changes on top of clean remote state
#   4. Run extension sync (special — talks to Cursor, see editor/sync.sh)
#   5. Stage all changes and push a sync/ branch
#   6. GitHub Actions creates a PR with your review requested
#   7. Merge branch into local main so changes reflect immediately
#
# If a PR is rejected:
#   Next sync resets to remote (which doesn't have the changes),
#   but local file edits still exist on disk, so they'll be
#   picked up and pushed again. To truly discard, undo the file edits.
#
# Extension sync is special because it doesn't just track files —
# it talks to Cursor to install/uninstall extensions and update
# extensions.txt accordingly. See personal/config/editor/sync.sh.

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