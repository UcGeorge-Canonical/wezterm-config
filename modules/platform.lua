-- Platform/version detection and display-server workarounds.
-- Other modules can `require('modules.platform')` to use the helpers.
local wezterm = require 'wezterm'

local M = {}

local triple = wezterm.target_triple
M.is_linux = triple:find('linux') ~= nil
M.is_mac = triple:find('darwin') ~= nil
M.is_windows = triple:find('windows') ~= nil

-- Last stable release; a newer date-stamped version is a nightly/git build.
-- Use this ONLY for runtime-behaviour workarounds (crashes, rendering); gate
-- config options with M.has() instead, which asks the running binary.
M.STABLE = '20240203-110809-5046fc22'
local vdate = wezterm.version:match('^(%d%d%d%d%d%d%d%d%-%d%d%d%d%d%d)')
M.is_nightly = vdate ~= nil and vdate > M.STABLE:sub(1, 15)

-- True if the running wezterm knows this config option. Lets one config work
-- on both stable and nightly: `platform.set_if_supported(config, 'opt', v)`.
local known = {}
function M.has(option)
  if known[option] == nil then
    local probe = wezterm.config_builder()
    local ok, err = pcall(function() probe[option] = {} end)
    known[option] = ok or not tostring(err):find('is not a valid Config field', 1, true)
  end
  return known[option]
end

function M.set_if_supported(config, option, value)
  if M.has(option) then
    config[option] = value
    return true
  end
  return false
end

local session = os.getenv('XDG_SESSION_TYPE') or ''
M.is_wayland_session = M.is_linux and (session == 'wayland' or os.getenv('WAYLAND_DISPLAY') ~= nil)
M.is_gnome = (os.getenv('XDG_CURRENT_DESKTOP') or ''):lower():find('gnome') ~= nil

-- Stable 20240203 crashes at startup on newer Wayland compositors (GNOME 46+,
-- recent KDE: "Buffer size must be an integer multiple of the buffer_scale",
-- wezterm#7333/#7843, fixed by PR #7746 in nightly). It runs fine on XWayland.
-- Distro git snapshots from 2024-2025 may be "nightly" by date yet predate
-- the fix; force either way with WEZTERM_NATIVE_WAYLAND=1|0.
local force = os.getenv('WEZTERM_NATIVE_WAYLAND')
if force == '1' or force == '0' then
  M.native_wayland = M.is_wayland_session and force == '1'
else
  M.native_wayland = M.is_wayland_session and M.is_nightly
end

-- GNOME does not expose the cursor theme to Wayland clients (wezterm#1742);
-- read it once from gsettings and cache it across config reloads.
local function gnome_cursor()
  local cached = wezterm.GLOBAL.gnome_cursor
  if cached then return cached.theme, cached.size end
  local theme, size
  local function get(key)
    local ok, success, stdout = pcall(wezterm.run_child_process,
      { 'gsettings', 'get', 'org.gnome.desktop.interface', key })
    if ok and success then return (stdout:gsub("[%s']", '')) end
  end
  theme, size = get('cursor-theme'), tonumber(get('cursor-size') or '')
  wezterm.GLOBAL.gnome_cursor = { theme = theme or false, size = size or false }
  return theme, size
end

function M.apply(config)
  if M.is_wayland_session and not M.native_wayland then
    config.enable_wayland = false
  end
  if M.is_linux and M.is_gnome and not os.getenv('XCURSOR_THEME') then
    local theme, size = gnome_cursor()
    if theme then config.xcursor_theme = theme end
    if size then config.xcursor_size = size end
  end
end

return M
