return {
  {
    "nvim-telescope/telescope.nvim",
    version = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local telescope = require("telescope")

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = "move_selection_next",
              ["<C-k>"] = "move_selection_previous",
            },
          },
        },
      })

      local builtin = require("telescope.builtin")

      -- Общие бинды
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Поиск файлов" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Поиск текста (ripgrep)" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Открытые буферы" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Поиск по справке" })

      -- LSP бинды
      vim.keymap.set("n", "gd", builtin.lsp_definitions, { desc = "Go to definition" })
      vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "Go to references" })
      vim.keymap.set("n", "gi", builtin.lsp_implementations, { desc = "Go to implementations" })
      vim.keymap.set("n", "<leader>ds", builtin.lsp_document_symbols, { desc = "Document symbols" })
      vim.keymap.set("n", "<leader>ws", builtin.lsp_workspace_symbols, { desc = "Workspace symbols" })
    end
  }
}
