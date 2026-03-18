return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("codecompanion").setup({
      strategies = {
        chat = { adapter = "ollama" },
        inline = { adapter = "ollama" },
      },
      adapters = {
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            schema = {
              model = {
                default = "qwen2.5-coder:14b-instruct-q4_K_M",
              },
            },
          })
        end,
      },
    })

    vim.keymap.set("v", "<leader>ar", ":CodeCompanion ", { noremap = true, desc = "AI: Rewrite with prompt" })
    vim.keymap.set("v", "<leader>af", "<cmd>CodeCompanion fix syntax errors<cr>", { noremap = true, desc = "AI: Fix" })
    vim.keymap.set("v", "<leader>ac", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, desc = "AI: Add to chat" })

    vim.keymap.set("n", "<leader>ar", "ggVG:CodeCompanion ", { noremap = true, desc = "AI: Rewrite file" })
    vim.keymap.set("n", "<leader>af", "ggVG<cmd>CodeCompanion fix syntax errors<cr>", { noremap = true, desc = "AI: Fix file" })
    vim.keymap.set("n", "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, desc = "AI: Toggle chat" })
  end,
}
