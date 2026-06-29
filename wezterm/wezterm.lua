local wezterm = require("wezterm")

local config = wezterm.config_builder()

local is_windows = os.getenv("OS") and os.getenv("OS"):lower():find("windows")
local is_macos = wezterm.target_triple:lower():find("darwin") ~= nil

-- On Windows, open directly into WSL Ubuntu (on macOS, use the default shell)
if is_windows then
  config.default_prog = { "wsl.exe", "--distribution", "Ubuntu", "--exec", "/bin/zsh", "-l" }
end

-- Load bundled Hack Nerd Font from the config dir (no system install needed)
config.font_dirs = { wezterm.home_dir .. "/.config/wezterm/fonts" }

-- ui
config.color_scheme = "rose-pine-moon"
config.max_fps = 120
config.font = wezterm.font("Hack Nerd Font", { weight = "Regular" })

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.window_frame = {
  font = wezterm.font("Hack Nerd Font", { weight = "Bold" }),
}

config.inactive_pane_hsb = {
  saturation = 0.0,
  brightness = 0.5,
}

if is_windows then
  config.win32_system_backdrop = "Acrylic"
  config.window_background_opacity = 0.7
  config.window_frame.font_size = 10.0
end

if is_macos then
  config.macos_window_background_blur = 30
  config.window_background_opacity = 0.85
  config.window_frame.font_size = 12.0
end

-- Copy / paste with Ctrl+C / Ctrl+V
config.keys = {
  -- Ctrl+C copies when text is selected, otherwise sends interrupt (SIGINT)
  {
    key = "c",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, pane)
      local sel = window:get_selection_text_for_pane(pane)
      if sel and sel ~= "" then
        window:perform_action(wezterm.action.CopyTo("ClipboardAndPrimarySelection"), pane)
        window:perform_action(wezterm.action.ClearSelection, pane)
      else
        window:perform_action(wezterm.action.SendKey({ key = "c", mods = "CTRL" }), pane)
      end
    end),
  },
  -- Ctrl+V pastes from the clipboard
  {
    key = "v",
    mods = "CTRL",
    action = wezterm.action.PasteFrom("Clipboard"),
  },
  -- Ctrl+Shift+M maximizes the window on demand
  {
    key = "m",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window)
      window:maximize()
    end),
  },
  -- Ctrl+Shift+F toggles full-screen
  {
    key = "f",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ToggleFullScreen,
  },
}

return config
