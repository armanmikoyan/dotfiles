# Entry point for all dotfiles — sourced by ~/.zshrc
# Loads personal and work configurations in order
DOTFILES_DIR="$HOME/dotfiles"

# Personal setup
source "$DOTFILES_DIR/personal/setup.sh"

# Work setup
source "$DOTFILES_DIR/work/setup.sh"
