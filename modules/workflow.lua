-- Shell, environment, launch menu, domains.
local wezterm = require 'wezterm'
local platform = require 'modules.platform'

local M = {}

function M.apply(config)
  -- Keep TERM=xterm-256color unless the wezterm terminfo is installed
  -- (`infocmp wezterm`); see docs/config/lua/config/term.md.
  config.term = 'xterm-256color'

  config.launch_menu = {}
  if platform.is_linux or platform.is_mac then
    table.insert(config.launch_menu, { label = 'htop', args = { 'htop' } })
  end

  -- SSH hosts from ~/.ssh/config appear automatically as SSH domains
  -- (wezterm.default_ssh_domains()); reach them via the launcher (LEADER w
  -- shows workspaces; use ShowLauncherArgs{flags='DOMAINS'} for domains).

  -- Optional persistent sessions: a local mux server that survives closing
  -- the GUI. Uncomment both lines to always attach to it on startup.
  -- config.unix_domains = { { name = 'unix' } }
  -- config.default_gui_startup_args = { 'connect', 'unix' }
end

return M
