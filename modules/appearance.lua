-- Colors, fonts, window chrome.
local wezterm = require 'wezterm'
local platform = require 'modules.platform'

local M = {}

-- Pick scheme names with scripts/list-schemes.sh; an invalid name silently
-- falls back to the default palette (it is not a config error).
M.dark_scheme = 'Catppuccin Mocha'
M.light_scheme = 'Catppuccin Latte'

local function system_appearance()
  -- wezterm.gui is nil inside wezterm-mux-server; default to dark there.
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return 'Dark'
end

function M.scheme_for(appearance)
  return appearance:find('Dark') and M.dark_scheme or M.light_scheme
end

function M.apply(config)
  -- Follows the OS light/dark setting; wezterm reloads the config automatically
  -- when the system appearance changes.
  config.color_scheme = M.scheme_for(system_appearance())

  -- FiraCode Nerd Font (installed in ~/.local/share/fonts) carries the
  -- ligatures and icons. The rest are bundled with wezterm, so if FiraCode is
  -- ever missing you still get a working font, icons and emoji.
  config.font = wezterm.font_with_fallback {
    { family = 'FiraCode Nerd Font', weight = 'Regular' },
    'JetBrains Mono',
    'Symbols Nerd Font Mono',
    'Noto Color Emoji',
  }
  -- FiraCode's Regular bold looks heavy at small sizes; SemiBold reads better.
  config.font_rules = {
    {
      intensity = 'Bold',
      italic = false,
      font = wezterm.font_with_fallback {
        { family = 'FiraCode Nerd Font', weight = 'DemiBold' },
        'JetBrains Mono',
      },
    },
  }
  config.font_size = 11.5
  config.line_height = 1.05
  -- calt/liga/clig are the ligatures (=> != === -> |> ...). The extras are
  -- FiraCode stylistic sets; remove any you don't like:
  --   zero = slashed 0, ss02 = <= >= with flat bars, ss03 = & with a loop,
  --   ss05 = @ with a stem, cv29 = curly braces {} with a softer shape.
  -- To disable ligatures: { 'calt=0', 'clig=0', 'liga=0' }
  config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1', 'zero', 'ss02', 'ss03', 'ss05', 'cv29' }
  config.bold_brightens_ansi_colors = 'BrightAndBold'

  config.window_padding = { left = '1cell', right = '1cell', top = '0.5cell', bottom = '0.5cell' }
  config.adjust_window_size_when_changing_font_size = false
  config.initial_cols = 140
  config.initial_rows = 40
  config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }
  config.scrollback_lines = 20000

  config.default_cursor_style = 'SteadyBar'
  config.audible_bell = 'Disabled'
  config.visual_bell = {
    fade_in_duration_ms = 75,
    fade_out_duration_ms = 75,
    target = 'CursorColor',
  }

  -- 'TITLE|RESIZE' = native title bar (server-side on X11/XWayland). Slimmer
  -- options: 'RESIZE' (no title bar), 'INTEGRATED_BUTTONS|RESIZE' (window
  -- buttons drawn in the tab bar). Avoid 'NONE': it breaks resize/minimize.
  if platform.is_mac then
    config.window_decorations = 'RESIZE'
  elseif platform.native_wayland and platform.is_gnome then
    -- Mutter lacks xdg-decoration; on nightly 'TITLE|RESIZE' yields a window
    -- with no title bar and no frame (wezterm#4962/#6296).
    config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
  else
    config.window_decorations = 'TITLE|RESIZE'
  end
  config.window_close_confirmation = 'AlwaysPrompt'
end

return M
