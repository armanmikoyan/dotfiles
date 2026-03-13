# Personal environment setup
# Loads shell config, aliases, editor sync, and secrets

# Shell config
source "$DOTFILES_DIR/personal/config/exports.sh"
source "$DOTFILES_DIR/personal/config/functions.sh"
source "$DOTFILES_DIR/personal/config/completion.sh"
source "$DOTFILES_DIR/personal/config/prompt.sh"
source "$DOTFILES_DIR/personal/config/nvm.sh"

<<<<<<< Updated upstream
# Aliases
source "$DOTFILES_DIR/personal/config/aliases/shell.sh"
source "$DOTFILES_DIR/personal/config/aliases/git.sh"
source "$DOTFILES_DIR/personal/config/aliases/goto.sh"

# Editor
source "$DOTFILES_DIR/personal/config/editor/setup.sh"

# Secrets
source "$DOTFILES_DIR/personal/secrets/setup.sh"
=======
source "$DIR/config/aliases/shell.sh"
source "$DIR/config/aliases/git.sh"
source "$DIR/config/aliases/projects.sh"

if [[ -f "$DIR/secrets/.env" ]]; then
  source "$DIR/secrets/.env"
else
  echo "⚠ Missing: $DIR/secrets/.env\n  Create it by copying the sample:\n  cp $DIR/secrets/.env.sample $DIR/secrets/.env"
fi
>>>>>>> Stashed changes
