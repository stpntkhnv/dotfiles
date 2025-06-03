require("plugins")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.api.nvim_create_user_command("Config", function()
  require("config_ui").open()
end, {})

vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>')

vim.keymap.set("n", "<leader>w", function()
  local view = require("nvim-tree.view")
  local api = require("nvim-tree.api")

  if not view.is_visible() then
    api.tree.open()
    api.tree.focus()
  else
    if vim.bo.filetype ~= "NvimTree" then
      api.tree.focus()
    else
      vim.cmd("wincmd p")
    end
  end
end, { desc = "Toggle focus between file and tree" })

vim.keymap.set('n', '<F1>', function()
  local path = vim.fn.expand("%:p:h")
  vim.cmd("cd " .. path)
  require("nvim-tree.api").tree.change_root(path)
end, { desc = "Set current file dir as root" })

vim.keymap.set("n", "<leader>f", function()
  vim.lsp.buf.format()
end, { desc = "Format current buffer" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end
})

vim.opt.number = true
vim.opt.relativenumber = true
