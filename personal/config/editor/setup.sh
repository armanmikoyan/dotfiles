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
# Two-way sync between Cursor and ~/dotfiles/personal/config/editor/extensions.txt
# Step 1: Install — extensions in list but not in Cursor (e.g. after git pull)
# Step 2: Update — extensions in Cursor but not in list (e.g. manually installed)

if command -v cursor &>/dev/null && [[ -f "$EDITOR_DIR/extensions.txt" ]]; then
  installed=$(cursor --list-extensions 2>/dev/null)
  listed=$(cat "$EDITOR_DIR/extensions.txt")
  missing=0
  new_exts=()

  # Step 1: Install missing extensions from the list
  while IFS= read -r ext; do
    [[ -z "$ext" ]] && continue
    if ! echo "$installed" | grep -q "^$ext$"; then
      print -P "  %F{226}⚠ missing extension detected — installing $ext...%f"
      cursor --install-extension "$ext" 2>/dev/null
      missing=$((missing + 1))
    fi
  done <<< "$listed"

  [[ $missing -gt 0 ]] && print -P "  %F{green}✓ $missing extension(s) installed%f"

  # Step 2: Detect new extensions and update extensions.txt
  while IFS= read -r ext; do
    [[ -z "$ext" ]] && continue
    if ! echo "$listed" | grep -q "^$ext$"; then
      new_exts+=("$ext")
    fi
  done <<< "$installed"

  # If new extensions found, update extensions.txt and prompt to commit
  if [[ ${#new_exts[@]} -gt 0 ]]; then
    print -P "  %F{226}⚠ new extension(s) detected — updating extensions.txt%f"
    for ext in "${new_exts[@]}"; do
      print -P "    + $ext"
    done
    cursor --list-extensions > "$EDITOR_DIR/extensions.txt"
    print -P "  %F{226}⚠ commit extensions.txt to save changes%f"
  fi
fi
