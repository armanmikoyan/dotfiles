#!/bin/bash
set -e

# Homebrew
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Apps
brew list --cask iterm2 &>/dev/null || brew install --cask iterm2
brew list --cask cursor &>/dev/null || brew install --cask cursor

# nvm
if [[ ! -d "$HOME/.nvm" ]]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# .zshrc
if ! grep -q 'source ~/dotfiles/init.sh' ~/.zshrc 2>/dev/null; then
  echo 'source ~/dotfiles/init.sh' >> ~/.zshrc
fi
