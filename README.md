# dotfiles

Personal and work shell configuration, synced across machines.

## Setup

1. Clone the repo

   ```bash
   git clone git@github.com:armanmikoyan/dotfiles.git ~/dotfiles
   ```

2. Run the install script

   ```bash
   cd ~/dotfiles
   ./install.sh
   ```

   This installs Homebrew, iTerm2, Cursor, nvm, and wires up `~/.zshrc` automatically.

3. Open a new terminal — Oh My Zsh, plugins, symlinks, and iTerm2 preferences are set up on first shell load.

4. Generate SSH key and add to GitHub (see `keygen` and `pubkey` in `personal/config/functions.sh`)
5. Create `personal/secrets/.env` from `.env.sample`
6. Create `work/secrets/.env` from `.env.sample`
7. Create `~/.gitconfig.local` with your identity for this machine

   ```bash
   git config --file ~/.gitconfig.local user.name "Your Name"
   git config --file ~/.gitconfig.local user.email "you@example.com"
   ```

8. Run `sync-dotfiles` to install all Cursor extensions

## Git config

Shared settings (colors, rerere, pull rebase) live in `personal/config/.gitconfig`, symlinked to `~/.gitconfig` on first terminal open.

Machine-specific identity lives in `~/.gitconfig.local` (not synced). This lets you use different name/email on work vs personal machines. A warning is shown on shell startup if the file is missing.

## What `install.sh` does

Idempotent — safe to re-run. Skips anything already installed.

| Step | What     | How                                 |
| :--: | -------- | ----------------------------------- |
|  1   | Homebrew | Official install script             |
|  2   | iTerm2   | `brew install --cask iterm2`        |
|  3   | Cursor   | `brew install --cask cursor`        |
|  4   | nvm      | curl install from GitHub            |
|  5   | ~/.zshrc | Appends `source ~/dotfiles/init.sh` |

## What happens on first shell load

Handled automatically by the dotfiles config scripts:

- **Oh My Zsh** — installed if missing (`personal/config/omz.sh`)
- **Plugins** — `zsh-autosuggestions` and `zsh-syntax-highlighting` cloned if missing
- **Git config** — symlinked to `~/.gitconfig`
- **Cursor settings** — symlinked to Cursor's settings path
- **iTerm2 preferences** — configured to load/save from `personal/config/iterm2/`

## Oh My Zsh

Configured in `personal/config/omz.sh`. Used only as a plugin manager — the custom prompt in `prompt.sh` is preserved (`ZSH_THEME=""`).

Plugins:

- `zsh-autosuggestions` — suggests commands as you type (right arrow to accept)
- `zsh-syntax-highlighting` — colors valid commands green, invalid red

## iTerm2

Preferences are stored in `personal/config/iterm2/com.googlecode.iterm2.plist`. iTerm2 is configured via `defaults write` (in `personal/config/iterm2/setup.sh`) to read/write preferences from this folder. Changes made in iTerm2 are saved to the dotfiles on quit.

## Symlinks

Managed in `personal/config/symlinks.sh`, created automatically on first terminal open:

- `personal/config/.gitconfig` → `~/.gitconfig`
- `personal/config/editor/settings.json` → `~/Library/Application Support/Cursor/User/settings.json`

Existing files are backed up to `.bak` before symlinking.

## Automation

### Daily sync (`sync.sh`)

Runs daily at 7pm via cron (self-installs on first terminal open). Run manually anytime with the `sync-dotfiles` alias.

1. Stashes local changes to preserve uncommitted edits
2. Resets local main to match remote (remote is source of truth)
3. Re-applies stashed changes on top of clean remote state
4. Runs extension sync (see below)
5. Stages all changes across the repo
6. Pushes a `sync/` branch with conventional commit message
7. GitHub Actions creates a PR with your review requested
8. Merges branch into local main so changes reflect immediately

If a PR is rejected, the next sync resets to remote (changes gone from local commits), but local file edits still exist on disk so they'll be picked up again. To truly discard, undo the file edits.

### Extension sync (`personal/config/editor/sync.sh`)

Extensions need special handling because sync doesn't just track files — it talks to Cursor to install/uninstall extensions and update `extensions.txt` accordingly.

Two-way sync between Cursor and `extensions.txt`:

- **Install** an extension in Cursor → sync adds it to the file
- **Uninstall** an extension in Cursor → sync removes it from the file
- **New machine** → sync installs everything from the file
- **Delete `extensions.txt`** → sync recreates it from Cursor's extensions

**Do not edit `extensions.txt` manually.** Always install/uninstall through Cursor's UI.

#### How uninstall detection works

`.extensions.snapshot` (gitignored) stores what Cursor had at the end of the last sync.

| extensions.txt | Cursor  | .extensions.snapshot | Action                                    |
| :------------: | :-----: | :------------------: | ----------------------------------------- |
|     has it     | doesn't |        had it        | Uninstalled via Cursor → remove from file |
|     has it     | doesn't |    didn't have it    | New machine → install in Cursor           |
|    doesn't     | has it  |          —           | Newly installed → add to file             |

**Do not edit `.extensions.snapshot`.** If deleted, sync can't detect uninstalls — it will reinstall everything from `extensions.txt` instead. The file is recreated automatically on the next run.

### Settings sync

`settings.json` is symlinked into Cursor on first terminal open. Edit it in the dotfiles repo and Cursor picks it up immediately.
