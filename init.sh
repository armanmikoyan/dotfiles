DOTFILES_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"

source "$DOTFILES_DIR/personal/setup.sh"
source "$DOTFILES_DIR/work/setup.sh"
