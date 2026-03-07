DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"

source "$DIR/config/exports.sh"
source "$DIR/config/functions.sh"
source "$DIR/config/completion.sh"
source "$DIR/config/prompt.sh"
source "$DIR/config/nvm.sh"

source "$DIR/config/aliases/shell.sh"
source "$DIR/config/aliases/git.sh"
source "$DIR/config/aliases/projects.sh"

if [[ -f "$DIR/secrets/.env" ]]; then
  source "$DIR/secrets/.env"
else
  echo "Missing: .env\n  Create it by copying the sample:\n  .env.sample -> .env"
fi
