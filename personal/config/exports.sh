# English dates in terminal (system locale is Armenian)
export LC_TIME=en_US.UTF-8

# Pager: -R (color), -F (quit if fits on screen), -X (don't clear screen)
export LESS="-RFX"

# Local binaries
export PATH="$HOME/.local/bin:$PATH"

# VS Code CLI
export PATH="$PATH:$HOME/Downloads/Visual Studio Code.app/Contents/Resources/app/bin"

# Codex.app CLI (bundled binary, not on PATH by default)
export PATH="$PATH:/Applications/Codex.app/Contents/Resources"