return {
  {
    "nvimdev/lspsaga.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons"
    },
    config = function()
      require("lspsaga").setup({})
      vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { desc = "Code Action" })
    end
  }
}
