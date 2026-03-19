# Personal environment setup
# Loads shell config, aliases, editor sync, and secrets

# Oh My Zsh (plugin manager, no theme)
source "$DOTFILES_DIR/personal/config/omz.sh"

# Shell config
source "$DOTFILES_DIR/personal/config/exports.sh"
source "$DOTFILES_DIR/personal/config/functions.sh"
source "$DOTFILES_DIR/personal/config/prompt.sh"
source "$DOTFILES_DIR/personal/config/nvm.sh"

# Aliases
source "$DOTFILES_DIR/personal/config/aliases/shell.sh"
source "$DOTFILES_DIR/personal/config/aliases/git.sh"
source "$DOTFILES_DIR/personal/config/aliases/goto.sh"

# Symlinks
source "$DOTFILES_DIR/personal/config/symlinks.sh"

# iTerm2
source "$DOTFILES_DIR/personal/config/iterm2/setup.sh"

# Secrets
source "$DOTFILES_DIR/personal/secrets/setup.sh"

