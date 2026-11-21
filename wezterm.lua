-- WezTerm configuration entry point.
--
-- Layout (all under ~/.config/wezterm/, which is on wezterm's package.path):
--   wezterm.lua          this file: builds the config from modules
--   modules/*.lua        one concern per module, each exports apply(config)
--   local.lua            optional, per-machine overrides (not shared/committed)
--
-- The config is evaluated many times (startup, every reload, each new window
-- process, CLI subcommands). Keep this file and modules free of side effects:
-- no spawning processes, no writing files, no network at top level.
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Load modules fail-soft: an error in one module is logged (visible in the
-- debug overlay, CTRL+SHIFT+L) and skipped, instead of dropping the whole
-- config back to defaults. Order matters: later modules may read earlier values.
local modules = {
  'modules.platform',
  'modules.appearance',
  'modules.tabbar',
  'modules.keys',
  'modules.mouse',
  'modules.workflow',
  'modules.notify',
}

for _, name in ipairs(modules) do
  local ok, mod = pcall(require, name)
  if not ok then
    wezterm.log_error('failed to load ' .. name .. ': ' .. tostring(mod))
  else
    local applied, err = pcall(mod.apply, config)
    if not applied then
      wezterm.log_error('error applying ' .. name .. ': ' .. tostring(err))
    end
  end
end

-- Optional per-machine overrides: ~/.config/wezterm/local.lua returning
-- function(config) ... end
local has_local, local_overrides = pcall(require, 'local')
if has_local and type(local_overrides) == 'function' then
  local ok, err = pcall(local_overrides, config)
  if not ok then
    wezterm.log_error('error applying local.lua: ' .. tostring(err))
  end
elseif not has_local and not tostring(local_overrides):find("module 'local' not found", 1, true) then
  wezterm.log_error('failed to load local.lua: ' .. tostring(local_overrides))
end

return config
