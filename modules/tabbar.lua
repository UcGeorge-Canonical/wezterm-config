-- Tab bar and status line: rounded "pill" tabs coloured from the active
-- color scheme, plus a mode indicator (left) and workspace + clock (right).
local wezterm = require 'wezterm'
local nf = wezterm.nerdfonts

local M = {}

local LEFT_CAP = nf.ple_left_half_circle_thick
local RIGHT_CAP = nf.ple_right_half_circle_thick

local function basename(path)
  return (path or ''):gsub('/+$', ''):match('([^/\\]+)$') or path
end

-- pane.current_working_dir is a Url object since 20240127 (string before).
local function cwd_of(pane_info)
  local cwd = pane_info.current_working_dir
  if cwd == nil then return nil end
  if type(cwd) == 'string' then return cwd:gsub('^file://[^/]*', '') end
  return cwd.file_path
end

local function tab_title(tab)
  if tab.tab_title and #tab.tab_title > 0 then
    return tab.tab_title -- explicitly set (rename tab)
  end
  local pane = tab.active_pane
  local process = basename(pane.foreground_process_name or '')
  local shells = { bash = true, zsh = true, fish = true, sh = true, nu = true, pwsh = true }
  if process ~= '' and not shells[process] then
    return process
  end
  local cwd = cwd_of(pane)
  if cwd then
    if cwd == wezterm.home_dir then return '~' end
    return basename(cwd)
  end
  return pane.title
end

-- "~/src/project/sub" -> "…/project/sub": keeps the status bar compact.
local function short_path(path)
  path = (path or ''):gsub('/+$', '')
  local home = wezterm.home_dir
  if path:sub(1, #home) == home then path = '~' .. path:sub(#home + 1) end
  local last_two = path:match('([^/]+/[^/]+)$')
  if last_two and #path > #last_two + 2 then return '…/' .. last_two end
  return path == '' and '/' or path
end

local function battery_segment()
  local b = wezterm.battery_info()[1]
  if not b then return nil end
  local pct = math.floor(b.state_of_charge * 100 + 0.5)
  local level = math.max(10, math.min(100, math.floor((pct + 5) / 10) * 10))
  local charging = b.state == 'Charging' or b.state == 'Full'
  local name = 'md_battery' .. (charging and '_charging' or '') .. (level < 100 and ('_' .. level) or '')
  if charging and level == 100 then name = 'md_battery_charging_100' end
  local icon = nf[name] or nf.md_battery
  return { text = icon .. ' ' .. pct .. '%', low = pct <= 20 and not charging }
end

-- Derive tab-bar colours from the scheme so light/dark switching stays
-- consistent. Falls back to Catppuccin Mocha values for unknown schemes.
local function build_palette(scheme_name)
  local scheme = wezterm.color.get_builtin_schemes()[scheme_name] or {}
  local bg = wezterm.color.parse(scheme.background or '#1e1e2e')
  local fg = scheme.foreground or '#cdd6f4'
  local ansi = scheme.ansi or {}
  local is_dark = select(3, bg:hsla()) < 0.5
  local shift = is_dark and function(c, n) return c:lighten(n) end or function(c, n) return c:darken(n) end
  return {
    -- Same as the terminal background, so the bar blends into the window.
    bar_bg = bg,
    tab_bg = shift(bg, 0.08),
    tab_hover_bg = shift(bg, 0.16),
    tab_fg = is_dark and wezterm.color.parse(fg):darken(0.15):desaturate(0.3) or wezterm.color.parse(fg):lighten(0.15),
    active_bg = ansi[5] or '#89b4fa',
    active_fg = bg,
    accent = ansi[5] or '#89b4fa',
    mode = ansi[4] or '#f9e2af',
    danger = ansi[2] or '#f38ba8',
    fg = fg,
  }
end

local palettes = {}
local function palette_for(scheme_name)
  scheme_name = scheme_name or ''
  if not palettes[scheme_name] then palettes[scheme_name] = build_palette(scheme_name) end
  return palettes[scheme_name]
end

function M.apply(config)
  local p = palette_for(config.color_scheme)

  config.use_fancy_tab_bar = false
  config.tab_bar_at_bottom = false
  config.hide_tab_bar_if_only_one_tab = false
  config.tab_max_width = 32
  config.show_new_tab_button_in_tab_bar = true
  config.status_update_interval = 1000

  config.colors = config.colors or {}
  config.colors.tab_bar = {
    background = tostring(p.bar_bg),
    new_tab = { bg_color = tostring(p.bar_bg), fg_color = tostring(p.tab_fg) },
    new_tab_hover = { bg_color = tostring(p.tab_hover_bg), fg_color = p.fg },
  }

  -- Keep handlers cheap and synchronous: they run on every repaint.
  -- Only the first registered format-tab-title handler takes effect, so do not
  -- combine this with tab-bar plugins (tabline.wez, bar.wezterm).
  -- Handlers look the palette up from the window's live scheme instead of
  -- capturing `p`: on Wayland the first config evaluation can run before the
  -- dark/light setting is known, and the tabs then kept the wrong palette.
  wezterm.on('format-tab-title', function(tab, _, _, conf, hover, max_width)
    local p = palette_for(conf and conf.color_scheme)
    local bg, fg = p.tab_bg, p.tab_fg
    if tab.is_active then
      bg, fg = p.active_bg, p.active_fg
    elseif hover then
      bg, fg = p.tab_hover_bg, p.fg
    end
    local zoomed = tab.active_pane.is_zoomed and (' ' .. nf.md_magnify_plus_outline) or ''
    -- 4 cells reserved for the caps and the spaces around the text.
    local text = wezterm.truncate_right(
      string.format('%d %s%s', tab.tab_index + 1, tab_title(tab), zoomed), max_width - 4)
    return {
      { Background = { Color = tostring(p.bar_bg) } },
      { Foreground = { Color = tostring(bg) } },
      { Text = ' ' .. LEFT_CAP },
      { Background = { Color = tostring(bg) } },
      { Foreground = { Color = tostring(fg) } },
      { Attribute = { Intensity = tab.is_active and 'Bold' or 'Normal' } },
      { Text = text },
      { Background = { Color = tostring(p.bar_bg) } },
      { Foreground = { Color = tostring(bg) } },
      { Text = RIGHT_CAP },
    }
  end)

  wezterm.on('update-status', function(window, pane)
    local p = palette_for(window:effective_config().color_scheme)
    local left = {}
    local mode = window:active_key_table()
    local label
    if window:leader_is_active() then
      label = nf.md_keyboard_outline .. ' LEADER'
    elseif mode then
      label = nf.md_resize .. ' ' .. mode:upper()
    end
    if label then
      left = {
        { Background = { Color = tostring(p.bar_bg) } },
        { Foreground = { Color = p.mode } },
        { Text = ' ' .. LEFT_CAP },
        { Background = { Color = p.mode } },
        { Foreground = { Color = tostring(p.active_fg) } },
        { Attribute = { Intensity = 'Bold' } },
        { Text = label },
        { Background = { Color = tostring(p.bar_bg) } },
        { Foreground = { Color = p.mode } },
        { Text = RIGHT_CAP .. ' ' },
      }
    end
    window:set_left_status(wezterm.format(left))

    local right = { { Background = { Color = tostring(p.bar_bg) } } }
    local function seg(color, text)
      table.insert(right, { Foreground = { Color = tostring(color) } })
      table.insert(right, { Text = text .. '   ' })
    end

    local flash = wezterm.GLOBAL.flash
    if flash and os.time() <= flash.until_time then
      seg(p.mode, nf.md_check .. ' ' .. flash.text)
    end

    local cwd = pane:get_current_working_dir()
    if cwd then
      local host = cwd.host
      if host and host ~= '' and host ~= 'localhost' and host ~= wezterm.hostname() then
        seg(p.mode, nf.md_server_network .. ' ' .. host)
      end
      seg(p.tab_fg, nf.md_folder_outline .. ' ' .. short_path(cwd.file_path))
    end

    seg(p.accent, nf.cod_layers .. ' ' .. window:active_workspace())

    local battery = battery_segment()
    if battery then seg(battery.low and p.danger or p.tab_fg, battery.text) end

    table.insert(right, { Foreground = { Color = tostring(p.tab_fg) } })
    table.insert(right, { Text = nf.md_clock_outline .. ' ' .. wezterm.strftime('%H:%M') .. '  ' })
    window:set_right_status(wezterm.format(right))
  end)
end

return M
