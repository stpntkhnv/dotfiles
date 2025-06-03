local M = {}

function M.open()
  local buf = vim.api.nvim_create_buf(false, true)

  local lines = {
    "Настройки (пока просто заглушка)",
    "— тема: gruvbox",
    "— шрифт: JetBrainsMono Nerd Font",
    "— размер шрифта: 14",
  }

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = 40
  local height = #lines + 2
  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    border = "rounded",
  }

  vim.api.nvim_open_win(buf, true, opts)
end

return M

