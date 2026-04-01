#!/bin/bash

# Homebrew
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Apps
install_cask() {
  if brew list --cask "$1" &>/dev/null || [[ -n "$2" && -d "/Applications/$2" ]]; then
    echo "✓ $1 already installed"
    return
  fi
  echo "Installing $1..."
  if ! brew install --cask "$1"; then
    echo "✗ Failed to install $1" >&2
  fi
}
install_cask iterm2 "iTerm.app"
install_cask cursor "Cursor.app"
install_cask google-chrome@canary "Google Chrome Canary.app"
install_cask chromium "Chromium.app"

# nvm
if [[ ! -d "$HOME/.nvm" ]]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# .zshrc
if ! grep -q 'source ~/dotfiles/init.sh' ~/.zshrc 2>/dev/null; then
  echo 'source ~/dotfiles/init.sh' >> ~/.zshrc
fi
