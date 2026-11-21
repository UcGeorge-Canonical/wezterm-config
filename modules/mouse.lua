-- Mouse behaviour.
local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

function M.apply(config)
  config.mouse_bindings = {
    -- Plain click only selects; CTRL+click opens links (avoids accidental opens).
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'NONE',
      action = act.CompleteSelection 'ClipboardAndPrimarySelection',
    },
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
    },
    -- Swallow the CTRL+click down event so the app underneath does not see it.
    {
      event = { Down = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.Nop,
    },
  }
  config.hyperlink_rules = wezterm.default_hyperlink_rules()
  config.selection_word_boundary = " \t\n{}[]()\"'`,;:│"
end

return M
