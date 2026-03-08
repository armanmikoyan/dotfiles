# Loads work secrets (.env) into the shell environment
# If .env doesn't exist, warns with instructions to create it from the sample

if [[ -f "$DOTFILES_DIR/work/secrets/.env" ]]; then
  source "$DOTFILES_DIR/work/secrets/.env"
else
  print -P "  %F{196}✗ work secrets missing — create .env from .env.sample in ~/dotfiles/work/secrets/%f"
fi
