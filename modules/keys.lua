-- Key bindings: tmux-style LEADER layer on top of wezterm's defaults.
-- Inspect the effective table with: wezterm show-keys --lua
local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

-- CTRL+Space then a key (avoids clashing with tmux/readline CTRL+a).
-- Press CTRL+Space twice to send a literal CTRL+Space to the program.
M.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1000 }

local function leader(key, action, mods)
  return { key = key, mods = mods and ('LEADER|' .. mods) or 'LEADER', action = action }
end

function M.apply(config)
  config.leader = M.leader

  local keys = {
    leader('Space', act.SendKey { key = 'Space', mods = 'CTRL' }, 'CTRL'),

    -- panes
    leader('\\', act.SplitHorizontal { domain = 'CurrentPaneDomain' }),
    leader('|', act.SplitHorizontal { domain = 'CurrentPaneDomain' }, 'SHIFT'),
    leader('-', act.SplitVertical { domain = 'CurrentPaneDomain' }),
    leader('h', act.ActivatePaneDirection 'Left'),
    leader('j', act.ActivatePaneDirection 'Down'),
    leader('k', act.ActivatePaneDirection 'Up'),
    leader('l', act.ActivatePaneDirection 'Right'),
    leader('o', act.PaneSelect { mode = 'Activate' }),
    leader('O', act.PaneSelect { mode = 'SwapWithActive' }, 'SHIFT'),
    leader('z', act.TogglePaneZoomState),
    leader('x', act.CloseCurrentPane { confirm = true }),
    leader('r', act.ActivateKeyTable { name = 'resize_pane', one_shot = false, timeout_milliseconds = 3000 }),

    -- tabs
    leader('c', act.SpawnTab 'CurrentPaneDomain'),
    leader('n', act.ActivateTabRelative(1)),
    leader('p', act.ActivateTabRelative(-1)),
    leader('&', act.CloseCurrentTab { confirm = true }, 'SHIFT'),
    -- PromptInputLine: only `description` + `action` exist on stable 20240203;
    -- `prompt`/`initial_value` are nightly-only and are a hard error on stable.
    leader(',', act.PromptInputLine {
      description = 'Rename tab:',
      action = wezterm.action_callback(function(window, _, line)
        if line and #line > 0 then window:active_tab():set_title(line) end
      end),
    }),

    -- workspaces
    leader('w', act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' }),
    leader('s', act.PromptInputLine {
      description = 'New/switch workspace name:',
      action = wezterm.action_callback(function(window, pane, line)
        if line and #line > 0 then
          window:perform_action(act.SwitchToWorkspace { name = line }, pane)
        end
      end),
    }),
    leader(')', act.SwitchWorkspaceRelative(1), 'SHIFT'),
    leader('(', act.SwitchWorkspaceRelative(-1), 'SHIFT'),

    -- selection / search
    leader('[', act.ActivateCopyMode),
    leader('/', act.Search { CaseInSensitiveString = '' }),
    leader('Space', act.QuickSelect),
    leader(':', act.ActivateCommandPalette, 'SHIFT'),
    -- Cheatsheet in a new tab; quitting less (q) closes the tab.
    leader('?', act.SpawnCommandInNewTab {
      args = { 'less', wezterm.config_dir .. '/SHORTCUTS.md' },
    }, 'SHIFT'),
  }
  for i = 1, 9 do
    table.insert(keys, leader(tostring(i), act.ActivateTab(i - 1)))
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
