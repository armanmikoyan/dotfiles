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

# Copy my public key to the clipboard
alias pubkey='cat ~/.ssh/id_rsa.pub | pbcopy && echo "Public key copied to clipboard."'

# Show local IP address
alias ip='ipconfig getifaddr en0'

# Lock screen (sleep display immediately)
alias afk='pmset displaysleepnow'