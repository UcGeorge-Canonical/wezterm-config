-- Key bindings: tmux-style LEADER layer on top of wezterm's defaults.
-- Every binding is described once in `bindings`; the same list drives
-- config.keys and the searchable shortcut menu (LEADER ?), so they never drift.
-- Inspect the effective table with: wezterm show-keys --lua
local wezterm = require 'wezterm'
local act = wezterm.action
local actions = require 'modules.actions'

local M = {}

-- CTRL+Space then a key (avoids clashing with tmux/readline CTRL+a).
-- Press CTRL+Space twice to send a literal CTRL+Space to the program.
M.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1000 }

local KEY_NAMES = { Space = 'Space', UpArrow = '↑', DownArrow = '↓', LeftArrow = '←', RightArrow = '→' }

-- Human-readable chord, e.g. "Leader O", "Leader |", "Ctrl+Shift+↑".
local function chord(key, mods)
  local leader, words, shift = false, {}, false
  for m in (mods or ''):gmatch('[^|]+') do
    if m == 'LEADER' then leader = true
    elseif m == 'SHIFT' then shift = true
    else table.insert(words, m:sub(1, 1) .. m:sub(2):lower()) end
  end
  local name = KEY_NAMES[key] or key
  -- Capitals and shifted symbols (| & ( ) : ?) already imply Shift.
  if shift and #name > 1 then table.insert(words, 'Shift') end
  table.insert(words, shift and name:upper() or name)
  local s = table.concat(words, '+')
  return leader and ('Leader ' .. s) or s
end

-- `mods` of an entry are relative to LEADER unless `direct = true`.
local function full_mods(e)
  if e.direct then return e[4] end
  return e[4] and ('LEADER|' .. e[4]) or 'LEADER'
end

-- { group, description, key, mods, action, hidden?, direct? }
-- Hidden entries are bound but left out of the menu (duplicates, tab numbers).
local function bindings()
  local b = {
    { 'Panes', 'Split right', '\\', nil, act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { 'Panes', 'Split right', '|', 'SHIFT', act.SplitHorizontal { domain = 'CurrentPaneDomain' }, hidden = true },
    { 'Panes', 'Split down', '-', nil, act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { 'Panes', 'Move to left pane', 'h', nil, act.ActivatePaneDirection 'Left' },
    { 'Panes', 'Move to pane below', 'j', nil, act.ActivatePaneDirection 'Down' },
    { 'Panes', 'Move to pane above', 'k', nil, act.ActivatePaneDirection 'Up' },
    { 'Panes', 'Move to right pane', 'l', nil, act.ActivatePaneDirection 'Right' },
    { 'Panes', 'Pick pane by label', 'o', nil, act.PaneSelect { mode = 'Activate' } },
    { 'Panes', 'Swap with picked pane', 'O', 'SHIFT', act.PaneSelect { mode = 'SwapWithActive' } },
    { 'Panes', 'Zoom / unzoom pane', 'z', nil, act.TogglePaneZoomState },
    { 'Panes', 'Close pane', 'x', nil, act.CloseCurrentPane { confirm = true } },
    { 'Panes', 'Resize mode (hjkl/arrows, Esc)', 'r', nil,
      act.ActivateKeyTable { name = 'resize_pane', one_shot = false, timeout_milliseconds = 3000 } },

    { 'Tabs', 'New tab', 'c', nil, act.SpawnTab 'CurrentPaneDomain' },
    { 'Tabs', 'Next tab', 'n', nil, act.ActivateTabRelative(1) },
    { 'Tabs', 'Previous tab', 'p', nil, act.ActivateTabRelative(-1) },
    { 'Tabs', 'Close tab', '&', 'SHIFT', act.CloseCurrentTab { confirm = true } },
    -- PromptInputLine: only `description` + `action` exist on stable 20240203;
    -- `prompt`/`initial_value` are nightly-only and are a hard error on stable.
    { 'Tabs', 'Rename tab', ',', nil, act.PromptInputLine {
      description = 'Rename tab:',
      action = wezterm.action_callback(function(window, _, line)
        if line and #line > 0 then window:active_tab():set_title(line) end
      end),
    } },

    { 'Workspaces', 'Open project (zoxide) as workspace', 'f', nil, actions.project_picker() },
    { 'Workspaces', 'Pick workspace', 'w', nil, act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
    { 'Workspaces', 'New / switch workspace by name', 's', nil, act.PromptInputLine {
      description = 'New/switch workspace name:',
      action = wezterm.action_callback(function(window, pane, line)
        if line and #line > 0 then
          window:perform_action(act.SwitchToWorkspace { name = line }, pane)
        end
      end),
    } },
    { 'Workspaces', 'Next workspace', ')', 'SHIFT', act.SwitchWorkspaceRelative(1) },
    { 'Workspaces', 'Previous workspace', '(', 'SHIFT', act.SwitchWorkspaceRelative(-1) },

    -- Overrides the default CTRL+SHIFT+Up/Down pane moves (still on Leader k/j).
    { 'Output', 'Jump to previous prompt', 'UpArrow', 'CTRL|SHIFT', act.ScrollToPrompt(-1), direct = true },
    { 'Output', 'Jump to next prompt', 'DownArrow', 'CTRL|SHIFT', act.ScrollToPrompt(1), direct = true },
    { 'Output', 'Copy last command output', 'y', nil, actions.copy_last_output() },
    { 'Output', 'Open scrollback in editor / pager', 'e', nil, actions.edit_scrollback() },
    { 'Output', 'Copy mode (vim keys, v/y, Esc)', '[', nil, act.ActivateCopyMode },
    { 'Output', 'Search scrollback', '/', nil, act.Search { CaseInSensitiveString = '' } },
    { 'Output', 'Quick select (URLs, hashes, paths)', 'Space', nil, act.QuickSelect },

    { 'View', 'Toggle translucent background', 't', nil, actions.toggle_opacity() },
    { 'View', 'Toggle presentation mode (big font)', 'P', 'SHIFT', actions.toggle_presentation() },

    { 'Config', 'Reload config (also Ctrl+Shift+R)', 'R', 'SHIFT', actions.reload_config() },

    { 'Help', 'Search & run shortcuts', '?', 'SHIFT', nil }, -- action filled in below
    { 'Help', 'Command palette', ':', 'SHIFT', act.ActivateCommandPalette },
    { 'Help', 'Send literal CTRL+Space', 'Space', 'CTRL', act.SendKey { key = 'Space', mods = 'CTRL' }, hidden = true },
  }
  for i = 1, 9 do
    table.insert(b, { 'Tabs', 'Go to tab ' .. i, tostring(i), nil, act.ActivateTab(i - 1), hidden = true })
  end
  return b
end

-- wezterm's own defaults worth finding in the menu (not rebound here).
local DEFAULTS = {
  { 'Clipboard', 'Copy', 'Ctrl+Shift+C', act.CopyTo 'Clipboard' },
  { 'Clipboard', 'Paste', 'Ctrl+Shift+V', act.PasteFrom 'Clipboard' },
  { 'Tabs', 'New tab', 'Ctrl+Shift+T', act.SpawnTab 'CurrentPaneDomain' },
  { 'Tabs', 'Close tab', 'Ctrl+Shift+W', act.CloseCurrentTab { confirm = true } },
  { 'Window', 'New window', 'Ctrl+Shift+N', act.SpawnWindow },
  { 'Window', 'Toggle fullscreen', 'Alt+Enter', act.ToggleFullScreen },
  { 'View', 'Bigger font', 'Ctrl+=', act.IncreaseFontSize },
  { 'View', 'Smaller font', 'Ctrl+-', act.DecreaseFontSize },
  { 'View', 'Reset font size', 'Ctrl+0', act.ResetFontSize },
  { 'Output', 'Clear scrollback', 'Ctrl+Shift+K', act.ClearScrollback 'ScrollbackOnly' },
  { 'Tools', 'Emoji / character picker', 'Ctrl+Shift+U', act.CharSelect },
  { 'Config', 'Debug overlay (errors, Lua REPL)', 'Ctrl+Shift+L', act.ShowDebugOverlay },
}

local function shortcut_menu(entries)
  local items = {}
  for _, e in ipairs(entries) do
    if not e.hidden and e[5] then
      table.insert(items, { e[1], e[2], chord(e[3], full_mods(e)), e[5] })
    end
  end
  for _, d in ipairs(DEFAULTS) do table.insert(items, d) end
  table.insert(items, { 'Help', 'Open full cheatsheet (SHORTCUTS.md)', '',
    act.SpawnCommandInNewTab { args = { 'less', wezterm.config_dir .. '/SHORTCUTS.md' } } })

  local choices = {}
  for i, it in ipairs(items) do
    table.insert(choices, { id = tostring(i), label = string.format('%-11s %-38s %s', it[1], it[2], it[3]) })
  end
  return act.InputSelector {
    title = 'Shortcuts',
    fuzzy = true,
    fuzzy_description = 'Search shortcuts: ',
    choices = choices,
    action = wezterm.action_callback(function(window, pane, id)
      local item = id and items[tonumber(id)]
      if item then window:perform_action(item[4], pane) end
    end),
  }
end

function M.apply(config)
  config.leader = M.leader

  local entries = bindings()
  for _, e in ipairs(entries) do
    if e[3] == '?' then e[5] = shortcut_menu(entries) end
  end

  local keys = {}
  for _, e in ipairs(entries) do
    table.insert(keys, { key = e[3], mods = full_mods(e), action = e[5] })
  end
  config.keys = keys

  config.key_tables = {
    resize_pane = {
      { key = 'h', action = act.AdjustPaneSize { 'Left', 3 } },
      { key = 'j', action = act.AdjustPaneSize { 'Down', 3 } },
      { key = 'k', action = act.AdjustPaneSize { 'Up', 3 } },
      { key = 'l', action = act.AdjustPaneSize { 'Right', 3 } },
      { key = 'LeftArrow', action = act.AdjustPaneSize { 'Left', 3 } },
      { key = 'DownArrow', action = act.AdjustPaneSize { 'Down', 3 } },
      { key = 'UpArrow', action = act.AdjustPaneSize { 'Up', 3 } },
      { key = 'RightArrow', action = act.AdjustPaneSize { 'Right', 3 } },
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'Enter', action = 'PopKeyTable' },
    },
  }
end

return M
