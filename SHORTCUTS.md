# WezTerm shortcuts

Searchable menu in WezTerm: CTRL+Space then ?   (type to filter, Enter runs it;
the last entry opens this sheet, q closes it)
Source of truth: ~/.config/wezterm/modules/keys.lua (custom), wezterm defaults.
Print every active binding:  wezterm show-keys --lua

## Leader: CTRL+Space, then the key (within 1 second)

Panes
  \  or  |        Split right
  -               Split down
  h j k l         Move to pane left / down / up / right
  o               Pick pane by label
  O               Swap active pane with a picked one
  z               Zoom / unzoom pane
  x               Close pane
  r               Resize mode: h j k l or arrows, Esc / Enter to exit

Tabs
  c               New tab
  n / p           Next / previous tab
  1 .. 9          Go to tab N
  ,               Rename tab
  &               Close tab

Workspaces & projects
  f               Project picker: fuzzy-pick a zoxide directory, open it as a workspace
  w               Fuzzy-pick workspace
  s               New / switch workspace by name
  ( / )           Previous / next workspace

Selection & tools
  [               Copy mode (vim keys, v to select, y to copy, Esc to exit)
  /               Search scrollback
  Space           Quick select (URLs, hashes, paths) and copy
  y               Copy the last command's output
  e               Open scrollback in $EDITOR (or less)
  R               Reload config (same as CTRL+SHIFT+R; saving a file also reloads)
  :               Command palette
  ?               Searchable shortcut menu (runs the picked action)

View
  t               Toggle translucent background
  P               Toggle presentation mode (big font)
  CTRL+Space      Send a literal CTRL+Space to the program

## Direct keys (no leader)

  CTRL+SHIFT+Up / Down      Jump to previous / next shell prompt
                            (replaces the default pane-move; use Leader k / j)

## Useful wezterm defaults (no leader)

  CTRL+SHIFT+C / V          Copy / paste
  CTRL+SHIFT+T / W          New tab / close tab
  CTRL+SHIFT+N              New window
  CTRL+Tab / CTRL+SHIFT+Tab Next / previous tab
  CTRL+SHIFT+1 .. 9         Go to tab N
  CTRL+SHIFT+PageUp/Down    Move tab left / right
  CTRL+SHIFT+ALT+arrows     Resize pane
  CTRL+SHIFT+Z              Zoom pane
  CTRL+SHIFT+X              Copy mode
  CTRL+SHIFT+F              Search
  CTRL+SHIFT+Space          Quick select
  CTRL+SHIFT+P              Command palette
  CTRL+SHIFT+U              Emoji / character picker
  CTRL+SHIFT+K              Clear scrollback
  SHIFT+PageUp / PageDown   Scroll a page
  CTRL+= / CTRL+- / CTRL+0  Font bigger / smaller / reset
  ALT+Enter                 Toggle fullscreen
  CTRL+SHIFT+R              Reload config
  CTRL+SHIFT+L              Debug overlay (config errors, Lua REPL)

## Mouse

  Click / drag              Select and copy to clipboard
  Double / triple click     Select word / line
  CTRL+click                Open link (URLs, Jira keys like ABC-123, LP: #123456)

## Shell (shell/init.bash)

  →  /  End / CTRL+F        Accept the grey autosuggestion (ble.sh)
  ALT+F / CTRL+→            Accept one word of it
  Up / Down                 History matching what you've typed (plain history if empty)
  Tab                       Completion menu (arrows / Tab to move, Enter to pick)
  CTRL+R                    Fuzzy history search (fzf)
  CTRL+T                    Fuzzy-insert a file path (with bat preview)
  ALT+C                     Fuzzy cd into a subdirectory (with tree preview)
  z foo / zi                Jump to a frequent dir matching "foo" / pick with fzf
  ls ll la lt               eza listings: plain, long + git, all, tree
  bat FILE / cat FILE       Syntax-highlighted view (cat = no pager)

  Notifications: commands running 10s+ send a desktop notification when they
  finish, if you're looking at another window or pane.
