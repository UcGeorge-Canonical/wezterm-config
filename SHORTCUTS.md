# WezTerm shortcuts

Open this sheet from WezTerm: CTRL+Space then ?   (q closes it)
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

Workspaces
  w               Fuzzy-pick workspace
  s               New / switch workspace by name
  ( / )           Previous / next workspace

Selection & tools
  [               Copy mode (vim keys, v to select, y to copy, Esc to exit)
  /               Search scrollback
  Space           Quick select (URLs, hashes, paths) and copy
  :               Command palette
  ?               This cheatsheet
  CTRL+Space      Send a literal CTRL+Space to the program

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
  CTRL+click                Open link
