# dotfiles

Personal and work shell configuration, synced across machines.

## Setup

1. Clone the repo

   ```bash
   git clone git@github.com:armanmikoyan/dotfiles.git ~/dotfiles
   ```

2. Add this line to `~/.zshrc`

   ```bash
   source ~/dotfiles/init.sh
   ```

3. Run `source ~/.zshrc`
4. Add SSH key to GitHub
5. Create `personal/secrets/.env` from `.env.sample`
6. Create `work/secrets/.env` from `.env.sample`
7. Run `sync-dotfiles` to install all Cursor extensions

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
