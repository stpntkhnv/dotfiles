local M = {}

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
end

function M.setup()
  -- Leader keys
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "

  -- 📁 NvimTree
  map("n", "<leader>w", function()
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
  end, "Toggle focus between file and tree")

  -- 🧹 LSP formatting
  map("n", "<leader>ff", function()
    vim.lsp.buf.format()
  end, "Format current buffer")

  -- 📑 Buffers
  map("n", "<Tab>", "<cmd>BufferLineCycleNext<CR>", "Next buffer")
  map("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", "Previous buffer")

  map("n", "<leader>x", function()
    local current = vim.api.nvim_get_current_buf()
    vim.cmd("bprevious")
    vim.cmd("bdelete " .. current)
  end, "Close current buffer and go to previous")

  map("n", "<leader>X", ":%bd|e#|bd#<CR>", "Close all buffers except current")
end

function M.set_dotnet_keymaps(bufnr)
  map("n", "gh", "<cmd>Lspsaga lsp_finder<CR>")
  map("n", "gd", "<cmd>Lspsaga peek_definition<CR>")
  map("n", "gr", "<cmd>Lspsaga rename<CR>")
  map("n", "K", "<cmd>Lspsaga hover_doc<CR>")
  map("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>")
  map("n", "[e", "<cmd>Lspsaga diagnostic_jump_prev<CR>")
  map("n", "]e", "<cmd>Lspsaga diagnostic_jump_next<CR>")
end


return M

