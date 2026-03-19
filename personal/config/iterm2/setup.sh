# iTerm2 — load/save preferences from dotfiles
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DOTFILES_DIR/personal/config/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile_selection -int 2
