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

# Colorized ls (macOS only)
alias ls='ls -G'

# Enable aliases to be sudo’ed
alias sudo='sudo '

# Colorized grep
alias grep='grep --color=auto'

# Open Chrome from terminal
alias chrome='open -a "Google Chrome"'
alias canary='open -a "Google Chrome Canary"'
alias chromium='open -a "Chromium"'

# Lock screen (sleep display immediately)
alias afk='pmset displaysleepnow'

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

# Very important aliases
alias train='sl'
alias matrix='cmatrix'
alias idle='train && cmatrix';

# Run dotfiles sync
alias sync-dotfiles='$DOTFILES_DIR/sync.sh'
