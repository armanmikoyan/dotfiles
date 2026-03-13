EDITOR_DIR="$DOTFILES_DIR/personal/config/editor"
CURSOR_SETTINGS="$HOME/Library/Application Support/Cursor/User/settings.json"

# ── Settings ──────────────────────────────────────────────
# Symlinks settings.json so Cursor reads directly from dotfiles
# On first run, backs up existing settings to settings.json.bak
# To restore: rm the symlink, then rename .bak back to settings.json
# Backup location: ~/Library/Application Support/Cursor/User/settings.json.bak

if [[ ! -L "$CURSOR_SETTINGS" && -f "$EDITOR_DIR/settings.json" ]]; then
  [[ -f "$CURSOR_SETTINGS" ]] && mv "$CURSOR_SETTINGS" "$CURSOR_SETTINGS.bak"
  ln -s "$EDITOR_DIR/settings.json" "$CURSOR_SETTINGS"
fi

# Detect uncommitted changes and prompt to commit
if ! git -C "$EDITOR_DIR" diff --quiet -- settings.json 2>/dev/null; then
  print -P "  %F{226}⚠ settings.json has changed — commit to save changes%f"
fi

# ── Extensions ────────────────────────────────────────────
# Two-way sync runs daily via cron (see sync.sh)
# Installs cron entry on first run if missing
if ! crontab -l 2>/dev/null | grep -q 'editor/sync.sh'; then
  (crontab -l 2>/dev/null; echo "0 10 * * * $EDITOR_DIR/sync.sh") | crontab -
fi
alias sync-extensions='$DOTFILES_DIR/personal/config/editor/sync.sh'
