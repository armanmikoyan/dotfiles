export NVM_DIR="$HOME/.nvm"

[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# Auto-use .nvmrc on cd
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path node_version

  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    node_version="$(cat "$nvmrc_path")"

    if [ "$(nvm version)" != "v$node_version" ]; then
      nvm use "$node_version" >/dev/null
    fi
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc
