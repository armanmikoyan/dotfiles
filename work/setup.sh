# Work environment setup

<<<<<<< Updated upstream
# Exports — Android SDK paths
source "$DOTFILES_DIR/work/config/exports.sh"
=======
source "$DIR/config/exports.sh"
source "$DIR/config/aliases/projects.sh"
if [[ -f "$DIR/secrets/.env" ]]; then
  source "$DIR/secrets/.env"
else
  echo "Missing: .env\n  Create it by copying the sample:\n  .env.sample -> .env"
fi
>>>>>>> Stashed changes

# Aliases
source "$DOTFILES_DIR/work/config/aliases/goto.sh"

# Secrets
source "$DOTFILES_DIR/work/secrets/setup.sh"

# iOS dev — run manually when simulator is booted
alias trust-sim-cert='xcrun simctl keychain booted add-root-cert ~/.bitdefender-ca.pem'
