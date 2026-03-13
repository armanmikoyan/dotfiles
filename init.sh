# Entry point for all dotfiles — sourced by ~/.zshrc
DOTFILES_DIR="$HOME/dotfiles"

# Personal setup
source "$DOTFILES_DIR/personal/setup.sh"

# Work setup
source "$DOTFILES_DIR/work/setup.sh"

# Daily sync — extensions + dotfiles changes, creates PR via GitHub Actions
if ! crontab -l 2>/dev/null | grep -q 'dotfiles/sync.sh'; then
  (crontab -l 2>/dev/null; echo "0 10 * * * $DOTFILES_DIR/sync.sh") | crontab -
fi
alias sync-dotfiles='$DOTFILES_DIR/sync.sh'
