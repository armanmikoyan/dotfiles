DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"

source "$DIR/config/exports.sh"
source "$DIR/config/functions.sh"
source "$DIR/config/completion.sh"
source "$DIR/config/prompt.sh"
source "$DIR/config/nvm.sh"

source "$DIR/config/aliases/shell.sh"
source "$DIR/config/aliases/git.sh"
source "$DIR/config/aliases/projects.sh"
