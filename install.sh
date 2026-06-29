#!/usr/bin/env bash
# Symlinks the dotfiles into place. Works on macOS and Linux/WSL.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.backup.$(date +%s)"
    echo "backed up existing $dest"
  fi
  ln -sfn "$src" "$dest"
  echo "linked $dest -> $src"
}

# WezTerm config (read from ~/.wezterm.lua on both macOS and Windows)
link "$DOTFILES/wezterm/wezterm.lua" "$HOME/.wezterm.lua"

# Hack Nerd Font (config loads these via font_dirs)
mkdir -p "$HOME/.config/wezterm/fonts"
cp -f "$DOTFILES"/wezterm/fonts/*.ttf "$HOME/.config/wezterm/fonts/"
echo "copied fonts to ~/.config/wezterm/fonts"

# On macOS, also install fonts system-wide so all apps see them
if [ "$(uname)" = "Darwin" ]; then
  mkdir -p "$HOME/Library/Fonts"
  cp -f "$DOTFILES"/wezterm/fonts/*.ttf "$HOME/Library/Fonts/"
  echo "installed fonts to ~/Library/Fonts"
fi

# tmux config
link "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"

# zsh: source the Claude helpers from ~/.zshrc (idempotent)
ZSH_LINE='[ -f "$HOME/dotfiles/zsh/claude.zsh" ] && source "$HOME/dotfiles/zsh/claude.zsh"'
if [ -f "$HOME/.zshrc" ] && ! grep -qF 'dotfiles/zsh/claude.zsh' "$HOME/.zshrc"; then
  printf '\n# Claude Code session helpers (from dotfiles)\n%s\n' "$ZSH_LINE" >> "$HOME/.zshrc"
  echo "added Claude helpers source line to ~/.zshrc"
fi

echo "Done. Reload tmux with: tmux source-file ~/.tmux.conf, and restart your shell."
