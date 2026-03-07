# Show status of working directory
alias gs='git status'

# List branches
alias gb='git branch'

# Checkout branch
alias gch='git checkout'

# Show commit history with decorations
alias glog='git log --oneline --graph --all --decorate'

# Fast working directory cleanup
alias grh='git reset --hard HEAD'

# Amend commit with editing the message
alias gam='git commit --amend'

# Amend commit without editing the message
alias gamno='git commit --amend --no-edit'

# Restore working directory (accepts files, defaults to . if no args)
gr() { git restore "${@:-.}"; }

# Restore staging area (accepts files, defaults to . if no args)
grs() { git restore --staged "${@:-.}"; }

# Show diff of working directory (accepts files, defaults to . if no args)
gd() { git diff "${@:-.}"; }

# Show diff of staging area (accepts files, defaults to . if no args)
gds() { git diff --staged "${@:-.}"; }
