EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
CURSOR_SETTINGS="$HOME/Library/Application Support/Cursor/User/settings.json"
GITCONFIG="$DOTFILES_DIR/personal/config/.gitconfig"

# ── Git  (personal/config/.gitconfig → ~/.gitconfig), needs .gitconfig.local for identity
[[ ! -L "$HOME/.gitconfig" && -f "$GITCONFIG" ]] && {
  [[ -f "$HOME/.gitconfig" ]] && mv "$HOME/.gitconfig" "$HOME/.gitconfig.bak"
  ln -s "$GITCONFIG" "$HOME/.gitconfig"
}
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  print -P "  %F{196}✗ ~/.gitconfig.local missing — git commits won't have your identity%f"
  print -P "  %F{226}  Create it with:%f"
  print -P "  %F{255}  git config --file ~/.gitconfig.local user.name \"Your Name\"%f"
  print -P "  %F{255}  git config --file ~/.gitconfig.local user.email \"you@example.com\"%f"
fi

# ── Cursor (personal/config/editor/settings.json → ~/Library/Application Support/Cursor/User/settings.json)
[[ ! -L "$CURSOR_SETTINGS" && -f "$EDITOR_DIR/settings.json" ]] && {
  [[ -f "$CURSOR_SETTINGS" ]] && mv "$CURSOR_SETTINGS" "$CURSOR_SETTINGS.bak"
  ln -s "$EDITOR_DIR/settings.json" "$CURSOR_SETTINGS"
}
