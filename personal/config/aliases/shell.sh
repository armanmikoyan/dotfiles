# Easier directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Fast terminal cleanup
alias cc='clear'

# Reload .zshrc
alias rrc='source ~/.zshrc && echo "✓ zsh sourced"'

# Open .zshrc in current shell
alias orc='vim ~/.zshrc'

# Open dotfiles in Cursor
alias odf='cursor ~/dotfiles'

# Show local IP address (tries active interfaces)
alias ip='ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || ipconfig getifaddr en7 2>/dev/null || echo "no network"'

# Lock screen (sleep display immediately)
alias afk='pmset displaysleepnow'

# Run dotfiles sync
alias sync-dotfiles='$DOTFILES_DIR/sync.sh'