-- Custom actions used by modules/keys.lua. Each returns a wezterm action.
-- They run on key press (not at config evaluation), so spawning processes and
-- writing temp files here is fine.
local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

-- Short-lived message shown in the status bar (see modules/tabbar.lua).
function M.flash(message, seconds)
  wezterm.GLOBAL.flash = { text = message, until_time = os.time() + (seconds or 2) }
end

local function home_relative(path)
  local home = wezterm.home_dir
  if path:sub(1, #home) == home then
    return '~' .. path:sub(#home + 1)
  end
  return path
end

-- Fuzzy-pick a directory from zoxide's database and open it as a workspace
-- named after the directory (switches to it if it already exists).
function M.project_picker()
  return wezterm.action_callback(function(window, pane)
    local ok, success, stdout = pcall(wezterm.run_child_process, { 'zoxide', 'query', '--list' })
    if not ok or not success or stdout == '' then
      M.flash('No projects yet: cd around so zoxide learns your dirs', 4)
      return
    end
    local choices = {}
    for path in stdout:gmatch('[^\n]+') do
      table.insert(choices, { id = path, label = home_relative(path) })
    end
    window:perform_action(act.InputSelector {
      title = 'Open project as workspace',
      fuzzy = true,
      fuzzy_description = 'Project: ',
      choices = choices,
      action = wezterm.action_callback(function(win, p, id)
        if not id then return end
        local name = id:match('([^/]+)/*$') or id
        win:perform_action(act.SwitchToWorkspace { name = name, spawn = { cwd = id } }, p)
      end),
    }, pane)
  end)
end

-- Copy the output of the most recent command. Needs shell integration
-- (OSC 133 marks), which /etc/profile.d/wezterm.sh and shell/init.bash set up.
function M.copy_last_output()
  return wezterm.action_callback(function(window, pane)
    local zones = pane:get_semantic_zones('Output') or {}
    local zone = zones[#zones]
    local text = zone and pane:get_text_from_semantic_zone(zone):gsub('%s+$', '') or ''
    if text == '' then
      M.flash('No command output to copy')
      return
    end
    window:copy_to_clipboard(text, 'Clipboard')
    local _, newlines = text:gsub('\n', '')
    M.flash(string.format('Copied %d line%s of output', newlines + 1, newlines == 0 and '' or 's'))
  end)
end

-- Dump the whole scrollback to a temp file and open it in $VISUAL/$EDITOR
-- (falls back to less at the bottom). The file is removed afterwards.
function M.edit_scrollback()
  return wezterm.action_callback(function(window, pane)
    local rows = pane:get_dimensions().scrollback_rows
    local text = pane:get_logical_lines_as_text(rows)
    local path = os.tmpname()
    local f = io.open(path, 'w')
    if not f then
      M.flash('Could not write scrollback to ' .. path)
      return
    end
    f:write(text)
    f:close()
    window:perform_action(act.SpawnCommandInNewTab {
      -- Local domain: the temp file lives on this machine even for SSH panes.
      domain = 'DefaultDomain',
      args = {
        'bash', '-c',
        'trap \'rm -f -- "$1"\' EXIT; ed="${VISUAL:-$EDITOR}"; '
          .. 'if [ -n "$ed" ]; then $ed "$1"; else less +G -- "$1"; fi',
        'scrollback', path,
      },
    }, pane)
  end)
end

-- Per-window overrides that toggle on and off.
local function toggle_override(key, on_value, label)
  return wezterm.action_callback(function(window)
    local overrides = window:get_config_overrides() or {}
    if overrides[key] == nil then
      overrides[key] = on_value
      M.flash(label .. ' on')
    else
      overrides[key] = nil
      M.flash(label .. ' off')
    end
    window:set_config_overrides(overrides)
  end)
end

-- GNOME does not blur behind translucent windows, so keep it subtle.
function M.toggle_opacity()
  return toggle_override('window_background_opacity', 0.90, 'Translucency')
end

function M.toggle_presentation()
  return toggle_override('font_size', 18.0, 'Presentation mode')
end

-- wezterm.GLOBAL survives the reload, so the flash shows on the new config.
function M.reload_config()
  return wezterm.action_callback(function(window, pane)
    M.flash('Config reloaded', 2)
    window:perform_action(wezterm.action.ReloadConfiguration, pane)
  end)
end

return M
