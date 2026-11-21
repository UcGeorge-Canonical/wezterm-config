# Interactive bash setup that pairs with the WezTerm config: Starship prompt,
# fzf, zoxide, eza and bat, all coloured by the terminal's Catppuccin palette.
#
# Hooked from ~/.bashrc (shell/install.sh adds this line):
#   [ -f ~/.config/wezterm/shell/init.bash ] && . ~/.config/wezterm/shell/init.bash
# Every tool is optional: missing ones are skipped.
# Set WCFG_NO_BLESH=1 to start a shell without ble.sh (autosuggestions).

[[ $- == *i* ]] || return 0

__wcfg_shell_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# ble.sh (autosuggestions, syntax highlighting) replaces bash's line editor.
# It is loaded first and attached last, after every other hook is in place.
if [[ ${WCFG_NO_BLESH-} != 1 && -z ${BLE_VERSION-} && -f "$HOME/.local/share/blesh/ble.sh" ]]; then
  . "$HOME/.local/share/blesh/ble.sh" --attach=none --rcfile="$__wcfg_shell_dir/blerc"
fi

# WezTerm shell integration (cwd tracking, prompt marks, user vars). Login
# shells already get it from /etc/profile.d; this covers non-login shells.
# The function check prevents installing the hooks twice.
if [[ -n "${WEZTERM_PANE-}" ]] && ! declare -F __wezterm_semantic_precmd >/dev/null \
  && [[ -f /etc/profile.d/wezterm.sh ]]; then
  . /etc/profile.d/wezterm.sh
fi

# --- fzf: CTRL+R history, CTRL+T files, ALT+C cd ----------------------------
if command -v fzf >/dev/null; then
  # ANSI colour names so fzf follows the terminal theme.
  export FZF_DEFAULT_OPTS="--height=45% --layout=reverse --border=rounded --info=inline-right \
--prompt='❯ ' --pointer='▌' --marker='┃' \
--color=bg+:-1,fg+:-1:bold,hl:blue,hl+:blue:bold,info:bright-black,prompt:magenta \
--color=pointer:magenta,marker:green,spinner:magenta,header:cyan,border:bright-black,gutter:-1"
  if command -v eza >/dev/null; then
    export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons=always {} | head -100'"
  fi
  if command -v batcat >/dev/null || command -v bat >/dev/null; then
    __wcfg_bat=$(command -v bat || command -v batcat)
    export FZF_CTRL_T_OPTS="--preview '$__wcfg_bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null'"
  fi
  if [[ ${BLE_VERSION-} ]]; then
    # ble.sh replaces readline, so fzf's `bind -x` widgets need its adapters.
    ble-import -d integration/fzf-completion
    ble-import -d integration/fzf-key-bindings
  else
    eval "$(fzf --bash)"
  fi
fi

# --- eza: ls with icons and git status ---------------------------------------
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -l --group-directories-first --icons=auto --git --header --time-style=relative'
  alias la='ll -a'
  alias lt='eza --tree --level=2 --group-directories-first --icons=auto --git-ignore'
fi

# --- bat: cat with syntax highlighting (Ubuntu names the binary batcat) ------
if command -v batcat >/dev/null && ! command -v bat >/dev/null; then
  alias bat='batcat'
fi
if command -v bat >/dev/null || command -v batcat >/dev/null; then
  # bat picks the dark/light theme from the terminal's background colour.
  if [[ -f "$HOME/.config/bat/themes/Catppuccin Mocha.tmTheme" ]]; then
    export BAT_THEME_DARK='Catppuccin Mocha' BAT_THEME_LIGHT='Catppuccin Latte'
  fi
  alias cat='bat --paging=never --style=plain'
fi

# --- Starship prompt -----------------------------------------------------------
if command -v starship >/dev/null; then
  export STARSHIP_CONFIG="$__wcfg_shell_dir/starship.toml"
  eval "$(starship init bash)"
fi

# --- WezTerm hook ordering ---------------------------------------------------
if declare -F __wezterm_semantic_precmd >/dev/null; then
  # Publish the exit code for WezTerm's "long command finished" notification.
  # Runs first, so it is set before WEZTERM_PROG is cleared.
  __wcfg_report_exit() { __wezterm_set_user_var WEZTERM_LAST_EXIT "$?"; }

  # Starship rebuilds PS1 in its own precmd. WezTerm's prompt marking must run
  # after it, or the OSC 133 marks are lost (prompt jumping / copy output).
  __wcfg_hooks=(__wcfg_report_exit)
  for __wcfg_fn in "${precmd_functions[@]}"; do
    [[ $__wcfg_fn == __wezterm_semantic_precmd || $__wcfg_fn == __wcfg_report_exit ]] \
      || __wcfg_hooks+=("$__wcfg_fn")
  done
  precmd_functions=("${__wcfg_hooks[@]}" __wezterm_semantic_precmd)
  unset __wcfg_hooks __wcfg_fn
fi

# --- zoxide: `z foo` jumps to frecent dirs, `zi` picks with fzf -------------
# Last, as zoxide recommends; it also feeds the WezTerm project picker.
if command -v zoxide >/dev/null; then
  eval "$(zoxide init bash)"
fi

unset __wcfg_bat

if [[ ${BLE_VERSION-} ]]; then
  ble-attach
fi
