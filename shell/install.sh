#!/usr/bin/env bash
# One-time shell setup for this WezTerm config. Safe to re-run.
#   - hooks shell/init.bash into ~/.bashrc (with a timestamped backup)
#   - installs the Ayu Mirage theme for bat (shell/bat/)
#   - installs ble.sh (autosuggestions) into ~/.local/share/blesh
#     (pass --update-blesh to refresh it)
# Tools come from apt:  sudo apt install starship zoxide eza bat fzf
# Font: FiraCode Nerd Font (https://github.com/ryanoasis/nerd-fonts/releases).
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
init="$dir/init.bash"
line="[ -f \"$init\" ] && . \"$init\""
line="${line//$HOME/\$HOME}"

if grep -qF 'wezterm/shell/init.bash' "$HOME/.bashrc" 2>/dev/null; then
  echo "~/.bashrc already sources init.bash"
else
  [ -f "$HOME/.bashrc" ] && cp -a "$HOME/.bashrc" "$HOME/.bashrc.bak.$(date +%Y%m%d-%H%M%S)"
  printf '\n# WezTerm config: prompt and shell tools (see %s)\n%s\n' "${init/#$HOME/\~}" "$line" >> "$HOME/.bashrc"
  echo "Added init.bash to ~/.bashrc"
fi

bat=$(command -v bat || command -v batcat || true)
if [ -n "$bat" ]; then
  themes="$("$bat" --config-dir)/themes"
  mkdir -p "$themes"
  cp "$dir"/bat/*.tmTheme "$themes"/
  "$bat" cache --build >/dev/null
  echo "Installed bat theme (Ayu Mirage)"
else
  echo "bat not installed; skipping themes"
fi

blesh="$HOME/.local/share/blesh"
if [ ! -f "$blesh/ble.sh" ] || [ "${1-}" = --update-blesh ]; then
  # Nightly is the build upstream recommends; releases lag behind bash 5.3.
  tmp=$(mktemp -d)
  curl -fsSL https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf - -C "$tmp"
  bash "$tmp/ble-nightly/ble.sh" --install "$HOME/.local/share" >/dev/null
  rm -rf "$tmp"
  echo "Installed ble.sh into $blesh"
else
  echo "ble.sh already installed (re-run with --update-blesh to refresh)"
fi

missing=()
for tool in starship zoxide eza fzf; do command -v "$tool" >/dev/null || missing+=("$tool"); done
[ -n "$bat" ] || missing+=(bat)
if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing (optional): ${missing[*]}  ->  sudo apt install ${missing[*]}"
fi
echo "Open a new terminal (or: exec bash -l) to load it."
