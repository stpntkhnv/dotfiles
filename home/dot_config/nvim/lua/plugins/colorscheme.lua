return {
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup {
        styles = {
          comments = { italic = false },
        },
        -- tokyonight's stock diff colors are nearly invisible (DiffChange sits
        -- almost on the editor background), so changed lines in diffview render
        -- as flat gray. Repaint the diff groups: green for added/changed, red
        -- for deleted, brighter green for the changed text itself.
        on_highlights = function(hl, c)
          hl.DiffAdd = { bg = '#273c2b' }
          hl.DiffChange = { bg = '#273c2b' }
          hl.DiffText = { bg = '#3f5f42' }
          hl.DiffDelete = { bg = '#4a2731' }
        end,
      }
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },
}
