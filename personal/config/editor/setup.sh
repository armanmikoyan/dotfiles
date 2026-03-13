EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
CURSOR_SETTINGS="$HOME/Library/Application Support/Cursor/User/settings.json"

# ── Settings ──────────────────────────────────────────────
# Symlinks settings.json so Cursor reads directly from dotfiles
# First run backs up existing settings to settings.json.bak

if [[ ! -L "$CURSOR_SETTINGS" && -f "$EDITOR_DIR/settings.json" ]]; then
  [[ -f "$CURSOR_SETTINGS" ]] && mv "$CURSOR_SETTINGS" "$CURSOR_SETTINGS.bak"
  ln -s "$EDITOR_DIR/settings.json" "$CURSOR_SETTINGS"
fi

if ! git -C "$EDITOR_DIR" diff --quiet -- settings.json 2>/dev/null; then
  print -P "  %F{226}⚠ settings.json changed — commit to save%f"
fi