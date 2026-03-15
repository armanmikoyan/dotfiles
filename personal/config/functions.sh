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

# Print Unicode code point(s) for a character or string
# Usage: codepoints ✗     → U+2717
#        codepoints hello  → U+0068 U+0065 U+006C U+006C U+006F
codepoints() {
  if [[ -z "$1" ]]; then
    echo "Usage: codepoints <char|string>"
    return 1
  fi
  local str="$1" i
  for (( i=0; i < ${#str}; i++ )); do
    printf "U+%04X " "'${str:$i:1}"
  done
  echo
}

# Char or code point → UTF encoding with colored binary breakdown
# Usage: utf-8 ✗  |  utf-8 ✗ -v (verbose)
utf-8()  { python3 ~/dotfiles/personal/config/utf.py 8 "$@"; }
utf-16() { python3 ~/dotfiles/personal/config/utf.py 16 "$@"; }
utf-32() { python3 ~/dotfiles/personal/config/utf.py 32 "$@"; }