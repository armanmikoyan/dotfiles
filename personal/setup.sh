# Personal environment setup
# Loads shell config, aliases, editor sync, and secrets

# Shell config
source "$DOTFILES_DIR/personal/config/exports.sh"
source "$DOTFILES_DIR/personal/config/functions.sh"
source "$DOTFILES_DIR/personal/config/completion.sh"
source "$DOTFILES_DIR/personal/config/prompt.sh"
source "$DOTFILES_DIR/personal/config/nvm.sh"

# Aliases
source "$DOTFILES_DIR/personal/config/aliases/shell.sh"
source "$DOTFILES_DIR/personal/config/aliases/git.sh"
source "$DOTFILES_DIR/personal/config/aliases/goto.sh"

# Symlinks
source "$DOTFILES_DIR/personal/config/symlinks.sh"

# Secrets
source "$DOTFILES_DIR/personal/secrets/setup.sh"

