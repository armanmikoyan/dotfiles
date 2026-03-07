DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"

source "$DIR/config/exports.sh"
source "$DIR/config/aliases/projects.sh"
if [[ -f "$DIR/secrets/.env" ]]; then
  source "$DIR/secrets/.env"
else
  echo "Missing: .env\n  Create it by copying the sample:\n  .env.sample -> .env"
fi

# Trust Bitdefender SSL cert on iOS simulator
xcrun simctl keychain booted add-root-cert ~/.bitdefender-ca.pem 2>/dev/null || true
