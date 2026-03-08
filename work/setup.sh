# Work environment setup
# Loads work-specific exports, aliases, secrets, and dev tools

# Exports — Android SDK paths
source "$DOTFILES_DIR/work/config/exports.sh"

# Aliases — hot folder
source "$DOTFILES_DIR/work/config/aliases/goto.sh"

# Secrets — loads work tokens from .env (warns if missing)
source "$DOTFILES_DIR/work/secrets/setup.sh"

# iOS dev — trust Bitdefender SSL cert on simulator
xcrun simctl keychain booted add-root-cert ~/.bitdefender-ca.pem 2>/dev/null || true
