-- Desktop notification when a long-running command finishes and you are not
-- looking at it. Relies on shell integration user vars: WEZTERM_PROG is set
-- while a command runs and cleared at the next prompt; shell/init.bash also
-- publishes WEZTERM_LAST_EXIT just before that.
local wezterm = require 'wezterm'

local M = {}

M.min_seconds = 10

local function human(seconds)
  if seconds < 60 then return seconds .. 's' end
  if seconds < 3600 then return string.format('%dm%02ds', seconds // 60, seconds % 60) end
  return string.format('%dh%02dm', seconds // 3600, (seconds % 3600) // 60)
end

function M.apply(_)
  wezterm.on('user-var-changed', function(window, pane, name, value)
    if name ~= 'WEZTERM_PROG' then return end
    -- GLOBAL survives config reloads, so a reload mid-command is harmless.
    local running = wezterm.GLOBAL.running_cmds or {}
    local id = tostring(pane:pane_id())
    if value ~= '' then
      running[id] = { cmd = value, started = os.time() }
    elseif running[id] then
      local job = running[id]
      running[id] = nil
      local elapsed = os.time() - job.started
      local watching = window:is_focused() and window:active_pane():pane_id() == pane:pane_id()
      if elapsed >= M.min_seconds and not watching then
        local code = pane:get_user_vars().WEZTERM_LAST_EXIT
        local ok = code == nil or code == '' or code == '0'
        local title = (ok and '✔ Finished' or ('✘ Failed (exit ' .. code .. ')')) .. ' in ' .. human(elapsed)
        window:toast_notification(title, job.cmd, nil, 8000)
      end
    end
    wezterm.GLOBAL.running_cmds = running
  end)
end

return M
