# dotfiles

My terminal setup — WezTerm + tmux. Cross-platform (Windows/WSL and macOS).

## Contents

- `wezterm/wezterm.lua` — WezTerm config (rose-pine-moon, Hack Nerd Font, custom copy/paste & maximize keys). Launches into WSL Ubuntu on Windows; uses the default shell on macOS.
- `wezterm/fonts/` — Hack Nerd Font, loaded by WezTerm via `font_dirs` (no system install required).
- `tmux/tmux.conf` — prefix remapped to `Ctrl+a`, vim-style pane keys.
- `zsh/claude.zsh` — Claude Code session helpers (`cc`, `ccr`, `ccname`, `ccls`).

## Install (macOS / Linux / WSL)

```sh
git clone https://github.com/Dorfu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The script symlinks `~/.wezterm.lua` and `~/.tmux.conf`, copies the fonts into
`~/.config/wezterm/fonts` (and `~/Library/Fonts` on macOS), and backs up any
existing files.

## Key bindings

### WezTerm
- `Ctrl+C` — copy if text selected, else interrupt (SIGINT)
- `Ctrl+V` — paste
- `Ctrl+Shift+M` — maximize window
- `Ctrl+Shift+F` / `Alt+Enter` — toggle full-screen

### tmux (prefix = `Ctrl+a`)
- `Ctrl+a |` — split side-by-side
- `Ctrl+a -` — split top/bottom
- `Ctrl+a h/j/k/l` — move between panes

### Claude Code session manager (zsh)
Name → uuid aliases on top of `claude` (store: `~/.config/cc/sessions.tsv`).
- `cc ls` — list saved name → uuid aliases
- `cc <name>` — resume the aliased conversation
- `cc new <name>` — start a brand-new session with a fixed uuid and launch it
- `cc add <name> <uuid>` — map a name to an existing session
- `cc rename <old> <new>` (alias `cc mv`) — rename an alias, keeps the uuid
- `cc rm <name>` — drop the alias only (conversation untouched)
- `cc scan` — list recent on-disk sessions with a first-message hint (to find uuids)
