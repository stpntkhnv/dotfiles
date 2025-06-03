local wezterm = require 'wezterm'

return {
  font = wezterm.font_with_fallback {
    "JetBrainsMono Nerd Font",
    "MesloLGS NF",
  },
  font_size = 12.5,
  enable_tab_bar = false,
  window_background_opacity = 0.94,
  color_scheme = "Catppuccin Mocha",
  window_decorations = "RESIZE",
  enable_wayland = false,
  hide_mouse_cursor_when_typing = true,
  adjust_window_size_when_changing_font_size = false,
  keys = {
    { key = "V", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
    { key = "C", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
  },
}
