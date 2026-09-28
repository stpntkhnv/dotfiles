local M = {}

function M.root()
  local file = vim.api.nvim_buf_get_name(0)
  local dir = (vim.bo.buftype == '' and file ~= '') and vim.fs.dirname(file) or vim.fn.getcwd()
  return vim.fs.root(dir, '.git') or dir
end

return M
