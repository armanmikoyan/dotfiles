# Oh My Zsh — plugin manager only (custom prompt preserved)
export ZSH="$HOME/.oh-my-zsh"

# Auto-install OMZ + plugins on first run
if [[ ! -d "$ZSH" ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi
[[ ! -d "$ZSH/custom/plugins/zsh-autosuggestions" ]] && \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH/custom/plugins/zsh-autosuggestions"
[[ ! -d "$ZSH/custom/plugins/zsh-syntax-highlighting" ]] && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH/custom/plugins/zsh-syntax-highlighting"

ZSH_THEME=""
DISABLE_AUTO_UPDATE="true"

# Case-insensitive and smart partial autocompletion (applied before OMZ runs compinit)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=** r:|=**'

plugins=(zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"
