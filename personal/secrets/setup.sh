# Loads personal secrets (.env) into the shell environment
# If .env doesn't exist, warns with instructions to create it from the sample

if [[ -f "$DOTFILES_DIR/personal/secrets/.env" ]]; then
  source "$DOTFILES_DIR/personal/secrets/.env"
else
  print -P "  %F{196}✗ personal secrets missing — create .env from .env.sample in ~/dotfiles/personal/secrets/%f"
fi
