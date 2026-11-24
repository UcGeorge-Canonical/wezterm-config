# wezterm-config

A polished, batteries-included [WezTerm](https://wezterm.org) setup for Linux
(built on Ubuntu / GNOME, Wayland). It also sets up the bash prompt and shell
tools, so the terminal and the shell look and behave as one thing.

- **Looks:** Ayu Mirage everywhere (terminal, prompt, fzf, bat, autosuggestions). FiraCode Nerd Font with ligatures. Rounded "pill" tabs on
  a tab bar that blends into the window.
- **Feels like tmux:** a `CTRL+Space` leader for panes, tabs and workspaces,
  plus a **searchable shortcut menu** (`CTRL+Space ?`) so you never have to
  memorise anything.
- **Shell:** a minimal two-line [Starship](https://starship.rs) prompt,
  fish-style **autosuggestions** and syntax highlighting
  ([ble.sh](https://github.com/akinomyoga/ble.sh)), fzf, zoxide, eza and bat.
  All of it uses the same palette.

```
~/src/project  main +1?2  v3.12  ⎈ prod   󱎫 12s                  10:35
❯ git sta█tus --short          ← grey text = suggestion from history, → accepts
```

## Features

### Terminal (WezTerm)

| Feature | How |
|---|---|
| Searchable shortcut menu: type to filter, Enter runs the action | `CTRL+Space ?` |
| Project picker: fuzzy-pick a directory you visit often (zoxide), open it as a workspace | `CTRL+Space f` |
| Jump between shell prompts in the scrollback | `CTRL+SHIFT+↑ / ↓` |
| Copy the last command's output | `CTRL+Space y` |
| Open the scrollback in `$EDITOR` (or `less`) | `CTRL+Space e` |
| Desktop notification when a command running 10s+ finishes while you're looking elsewhere | automatic |
| Clickable Jira keys (`ABC-123`) and Launchpad bugs (`LP: #123456`) | `CTRL+click` |
| Status bar: leader/mode, remote host, cwd, workspace, battery, clock | automatic |
| Translucent background / presentation mode (large font) | `CTRL+Space t` / `P` |
| Reload the config | `CTRL+Space R` or `CTRL+SHIFT+R` (saving a file also reloads) |

Panes, tabs, workspaces, copy mode and quick select are all on the leader. The
full list is in [SHORTCUTS.md](SHORTCUTS.md).

### Shell (bash)

| Feature | How |
|---|---|
| Autosuggestions from history as you type | `→` / `End` accepts, `ALT+F` accepts one word |
| Prefix history search: type `git` and cycle through only git commands | `↑ / ↓` |
| Syntax highlighting (unknown commands are underlined red) | automatic |
| Fuzzy history / file / directory pickers (fzf) | `CTRL+R` / `CTRL+T` / `ALT+C` |
| Jump to frequently used directories | `z proj`, `zi` (interactive) |
| `ls` with icons and git status | `ls`, `ll`, `la`, `lt` (tree) |
| Syntax-highlighted file viewer | `bat file`, and `cat` uses bat too |
| Neovim as `$EDITOR`/`$VISUAL` (git commits etc.) and `man` pager, if installed | automatic |
| Prompt: directory, git status, Python/Go/Rust/Node version, k8s/juju context, command duration, exit code, time; user and host shown over SSH | automatic |

## Prerequisites

- **WezTerm.** Use the nightly build on GNOME 46+ Wayland
  (`sudo apt install wezterm-nightly` from the
  [apt repo](https://wezterm.org/install/linux.html)). The stable build
  (20240203) crashes on recent GNOME/KDE Wayland; this config detects it and
  falls back to XWayland.
- **FiraCode Nerd Font.** Optional but recommended: WezTerm's bundled fonts
  are used if it's missing.
- **bash** for the shell part. The WezTerm part works with any shell.
- **Shell tools** (all optional; missing ones are skipped):
  `starship zoxide eza bat fzf` (all in the Ubuntu archive on recent releases), plus
  `curl`, `xz` and `git`.

## Install

```sh
# 1. Config
git clone https://github.com/UcGeorge-Canonical/wezterm-config.git ~/.config/wezterm

# 2. Shell tools
sudo apt install starship zoxide eza bat fzf

# 3. Font
mkdir -p ~/.local/share/fonts/FiraCodeNerdFont
curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip -o /tmp/FiraCode.zip
unzip -o /tmp/FiraCode.zip -d ~/.local/share/fonts/FiraCodeNerdFont && fc-cache -f

# 4. Shell setup: hooks ~/.bashrc (backed up first), installs ble.sh and bat themes
~/.config/wezterm/shell/install.sh
```

Then open a new WezTerm window. `install.sh` is safe to re-run; use
`install.sh --update-blesh` to update ble.sh.

If `~/.wezterm.lua` exists, it takes priority over this config. Rename it.

## Customising

- **Per-machine tweaks:** copy `local.lua.example` to `local.lua` (git-ignored).
  It runs last, so anything set there wins.
- **Theme:** `M.dark_scheme` / `M.light_scheme` in `modules/appearance.lua`
  (both are Ayu Mirage, so it stays dark; set a light scheme to follow GNOME).
  The tab bar, prompt, fzf and ble.sh follow it automatically. bat uses
  `shell/bat/ayu-mirage.tmTheme` (from
  [mathiasdonoso/ayu-bat](https://github.com/mathiasdonoso/ayu-bat), MIT).
  Replace it and update `BAT_THEME` in `shell/init.bash` if you change the theme.
- **Font, size, ligatures:** `modules/appearance.lua` (`harfbuzz_features`).
- **Keys:** `modules/keys.lua`. A single table drives both the bindings and the
  `CTRL+Space ?` menu, so new keys show up in the menu automatically.
- **Prompt:** `shell/starship.toml`. **Autosuggestions and highlighting:**
  `shell/blerc`.
- **Jira URL:** `M.jira_url` in `modules/mouse.lua`. **Notification threshold:**
  `M.min_seconds` in `modules/notify.lua`.

## Layout

| Path | Purpose |
|---|---|
| `wezterm.lua` | Entry point: loads each module fail-soft, then `local.lua` |
| `modules/platform.lua` | OS/Wayland/GNOME detection, version-feature probing |
| `modules/appearance.lua` | Theme, font, window, decorations |
| `modules/tabbar.lua` | Tab titles and status bar |
| `modules/keys.lua` | Key bindings and the shortcut menu |
| `modules/actions.lua` | Project picker, copy output, scrollback editor, toggles, reload |
| `modules/notify.lua` | Long-command notifications |
| `modules/mouse.lua` | Mouse bindings, hyperlink rules |
| `modules/workflow.lua` | TERM, launch menu |
| `shell/init.bash` | Bash setup, sourced from `~/.bashrc` |
| `shell/starship.toml` | Prompt |
| `shell/blerc` | ble.sh settings (suggestions, colours, Up/Down search) |
| `shell/install.sh` | One-time shell setup |
| `shell/bat/` | bat syntax theme matching the terminal |
| `SHORTCUTS.md` | Every shortcut |

## Troubleshooting

- **Config errors:** `CTRL+SHIFT+L` opens the debug overlay. A broken module is
  skipped and logged there; the rest still load.
- **WezTerm won't start on Wayland:** launch it once with
  `WAYLAND_DISPLAY= wezterm`, then fix the config.
- **Shell feels off:** start a shell without ble.sh using
  `WCFG_NO_BLESH=1 bash`. To remove the shell setup entirely, delete the
  `init.bash` line from `~/.bashrc`.
- **Prompt icons show as boxes:** the Nerd Font isn't installed or selected.
  Check with `wezterm ls-fonts | grep -i fira`.
- **No notifications:** they only fire for commands of 10s or more, and only
  if that window or pane isn't focused.
