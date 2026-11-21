# wezterm-config

My WezTerm setup: Catppuccin (follows GNOME light/dark), FiraCode Nerd Font
with ligatures, a tmux-style leader (CTRL+Space), and a minimal two-line
Starship prompt wired into WezTerm's shell integration.

Shortcuts: [SHORTCUTS.md](SHORTCUTS.md), or press CTRL+Space then `?` for a searchable menu.

## Features

- Pill tab bar; the status bar shows the leader/mode, the cwd, a remote host,
  the workspace, battery and a clock
- Project picker (zoxide dirs → workspaces); jump between prompts; copy the last command's output
- Desktop notification when a long command (10s+) finishes while you're looking elsewhere
- Clickable Jira keys and Launchpad bugs; scrollback in `$EDITOR`; translucency and presentation toggles
- Prompt: directory, git, language versions, k8s/juju context, duration, exit status, time

## Install on a new machine (Ubuntu)

```sh
git clone git@github.com:UcGeorge-Canonical/wezterm-config.git ~/.config/wezterm
sudo apt install starship zoxide eza bat fzf
~/.config/wezterm/shell/install.sh   # hooks ~/.bashrc, installs bat themes
```

Font: unzip `FiraCode.zip` from the
[Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases) into
`~/.local/share/fonts/FiraCodeNerdFont/`, then run `fc-cache -f`.

## Layout

| Path | Purpose |
|---|---|
| `wezterm.lua` | Entry point. Loads each module fail-soft, then the optional `local.lua` |
| `modules/platform.lua` | OS/Wayland detection, feature probing |
| `modules/appearance.lua` | Theme, font, window |
| `modules/tabbar.lua` | Tab titles and status bar |
| `modules/keys.lua` | Key bindings and the shortcut menu (one table drives both) |
| `modules/actions.lua` | Callbacks: project picker, copy output, scrollback editor, toggles |
| `modules/notify.lua` | Long-command notifications |
| `modules/mouse.lua` | Mouse bindings and hyperlink rules (`M.jira_url`) |
| `shell/init.bash` | Prompt and shell tools; sourced from `~/.bashrc` |
| `shell/starship.toml` | Prompt layout |
| `local.lua` | Per-machine overrides (git-ignored); see `local.lua.example` |
