# Generate ed25519 SSH key (accepts optional -f for custom path)
# Usage: keygen email@example.com
#        keygen email@example.com -f ~/.ssh/id_ed25519_work
keygen() {
  if [[ -z "$1" ]]; then
    echo "Usage: keygen email [-f path]"
    return 1
  fi
  local email="$1"; shift
  ssh-keygen -t ed25519 -C "$email" "$@"
}

# Copy public key to clipboard
pubkey() {
  if [[ -z "$1" ]]; then
    echo "Usage: pubkey <name>"
    echo "Available keys:"
    for f in ~/.ssh/*.pub; do
      [[ -f "$f" ]] && echo "  pubkey name: $(basename "$f" .pub)"
    done
    return 1
  fi
  if [[ ! -f "$HOME/.ssh/$1.pub" ]]; then
    echo "✗ ~/.ssh/$1.pub not found"
    return 1
  fi
  pbcopy < "$HOME/.ssh/$1.pub" && echo "✓ $1.pub copied to clipboard"
}
