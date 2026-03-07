DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"

source "$DIR/config/exports.sh"
source "$DIR/config/aliases/projects.sh"
source "$DIR/secrets/.env"

# Trust Bitdefender SSL cert on iOS simulator
xcrun simctl keychain booted add-root-cert ~/.bitdefender-ca.pem 2>/dev/null
