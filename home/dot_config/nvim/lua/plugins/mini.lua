-- All mini.nvim modules live in this single spec: lazy.nvim does not merge
-- multiple `config` functions for the same plugin — the last one silently
-- wins, which is how mini.statusline ended up never being set up.
return {
  {
    'echasnovski/mini.nvim',
    config = function()
      local ai = require 'mini.ai'
      ai.setup {
        n_lines = 500,
        custom_textobjects = {
          f = ai.gen_spec.treesitter { a = '@function.outer', i = '@function.inner' },
          c = ai.gen_spec.treesitter { a = '@class.outer', i = '@class.inner' },
          F = ai.gen_spec.function_call(),
        },
      }
      require('mini.surround').setup {
        mappings = {
          add = 'gsa',
          delete = 'gsd',
          find = 'gsf',
          find_left = 'gsF',
          highlight = 'gsh',
          replace = 'gsr',
          update_n_lines = 'gsn',
        },
      }

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
}
