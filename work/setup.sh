# Work environment setup

# Exports — Android SDK paths
source "$DOTFILES_DIR/work/config/exports.sh"

# Aliases
source "$DOTFILES_DIR/work/config/aliases/goto.sh"

# Secrets
source "$DOTFILES_DIR/work/secrets/setup.sh"

# iOS dev — run manually when simulator is booted
alias trust-sim-cert='xcrun simctl keychain booted add-root-cert ~/.bitdefender-ca.pem'
