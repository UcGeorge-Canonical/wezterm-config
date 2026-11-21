-- Mouse behaviour.
local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

-- CTRL+click opens these; change jira_url if your tickets live elsewhere.
M.jira_url = 'https://warthogs.atlassian.net/browse/'

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
  -- Jira keys like ABC-123. Uppercase-only to limit false positives; it will
  -- still underline things like UTF-8 on hover, which is harmless.
  table.insert(config.hyperlink_rules, {
    regex = [[\b([A-Z][A-Z0-9]{1,9}-[1-9][0-9]{0,6})\b]],
    format = M.jira_url .. '$1',
  })
  -- Launchpad bugs: "LP: #123456", "lp#123456", "LP #123456".
  table.insert(config.hyperlink_rules, {
    regex = [[\b[Ll][Pp]:? ?#([0-9]+)\b]],
    format = 'https://bugs.launchpad.net/bugs/$1',
  })
  config.selection_word_boundary = " \t\n{}[]()\"'`,;:│"
end

return M
