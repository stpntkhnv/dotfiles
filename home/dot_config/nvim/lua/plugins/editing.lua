return {
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = { modes = { char = { enabled = false } } },
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash jump' },
      { 'S', mode = { 'n', 'x', 'o' }, function() require('flash').treesitter() end, desc = 'Flash treesitter select' },
    },
  },
  {
    'MagicDuck/grug-far.nvim',
    cmd = 'GrugFar',
    opts = {},
    keys = {
      { '<leader>sR', function() require('grug-far').open { prefills = { paths = require('repo').root() } } end, desc = '[S]earch and [R]eplace in repo' },
      { '<leader>sR', function() require('grug-far').with_visual_selection { prefills = { paths = require('repo').root() } } end, mode = 'x', desc = '[S]earch and [R]eplace selection in repo' },
    },
  },
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
}
