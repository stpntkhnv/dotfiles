return {
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
}
