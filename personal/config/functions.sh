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