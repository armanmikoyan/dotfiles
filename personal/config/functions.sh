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

# Char/string → code points
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

# Code point(s) → character(s)
# Usage: fromcodepoints 2717           → ✗
#        fromcodepoints U+0061 U+0062  → ab
fromcodepoints() {
  if [[ -z "$1" ]]; then
    echo "Usage: fromcodepoints <hex|U+hex> ..."
    return 1
  fi
  local arg
  for arg in "$@"; do
    local hex="${arg#[Uu]+}"
    hex="${hex#0[xX]}"
    if [[ ! "$hex" =~ ^[0-9a-fA-F]+$ ]]; then
      echo "invalid code point: $arg"
      echo "Usage: fromcodepoints <hex|U+hex> ..."
      return 1
    fi
    printf "\\U$(printf '%08X' "0x$hex")"
  done
  echo
}

# Char or code point → UTF encoding with colored binary breakdown
# Usage: utf-8 ✗  |  utf-8 ✗ -v (verbose)
utf-8()  { python3 ~/dotfiles/personal/config/utf.py 8 "$@"; }
utf-16() { python3 ~/dotfiles/personal/config/utf.py 16 "$@"; }
utf-32() { python3 ~/dotfiles/personal/config/utf.py 32 "$@"; }

# URL encode/decode strings
# Usage: urlencode "hello world"  → hello%20world
#        urldecode "hello%20world" → hello world
urlencode() {
  if [[ $# -ne 1 ]]; then
    echo 'invalid: expected 1 argument, got '$#''
    echo 'Usage: urlencode "string" (use quotes if string has spaces)'
    return 1
  fi
  python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}
urldecode() {
  if [[ $# -ne 1 ]]; then
    echo 'invalid: expected 1 argument, got '$#''
    echo 'Usage: urldecode "encoded%20string" (use quotes if string has spaces)'
    return 1
  fi
  python3 -c "import urllib.parse,sys; print(urllib.parse.unquote(sys.argv[1]))" "$1"
}