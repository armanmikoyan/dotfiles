# Easier directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Fast terminal cleanup
alias cc='clear'

# Reload .zshrc
alias rrc='source ~/.zshrc && echo "zshrc reloaded"'
# Open .zshrc in current shell
alias orc='vim ~/.zshrc'

# Copy my public key to the clipboard
alias pubkey='cat ~/.ssh/id_rsa.pub | pbcopy && echo "Public key copied to clipboard."'

# Lock screen (sleep display immediately)
alias afk='pmset displaysleepnow'
