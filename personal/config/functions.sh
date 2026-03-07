# Generate ed25519 SSH key with dynamic email
keygen() {
  if [ -z "$1" ]; then
    echo "Usage: keygen your_email@example.com"
    return 1
  fi
  ssh-keygen -t ed25519 -C "$1"
}
