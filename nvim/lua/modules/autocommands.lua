local M = {}

function M.setup()
  vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function()
      vim.lsp.buf.format({ async = false })
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "lua",
    callback = function()
      vim.opt_local.tabstop = 2
      vim.opt_local.shiftwidth = 2
      vim.opt_local.expandtab = true
    end
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "json",
    callback = function()
      vim.opt_local.tabstop = 4
      vim.opt_local.shiftwidth = 4
      vim.opt_local.expandtab = true
    end
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "go",
    callback = function()
      vim.opt_local.tabstop = 4
      vim.opt_local.shiftwidth = 4
      vim.opt_local.expandtab = true
    end
  })
end

return M
