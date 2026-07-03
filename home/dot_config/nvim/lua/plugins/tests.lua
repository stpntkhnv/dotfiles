-- Tests live under <leader>T (capital): the lowercase <leader>t prefix belongs
-- to toggles (gitsigns blame, inlay hints, ...) and the two used to clash —
-- e.g. gitsigns' buffer-local <leader>tD shadowed "debug tests in file".
return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'Issafalcon/neotest-dotnet',
    },
    config = function()
      local neotest = require 'neotest'
      neotest.setup {
        adapters = {
          require 'neotest-dotnet' {
            dap = { justMyCode = false },
          },
        },
      }

      vim.keymap.set('n', '<leader>Tn', function()
        neotest.run.run()
      end, { desc = '[T]est: run [N]earest' })
      vim.keymap.set('n', '<leader>Tf', function()
        neotest.run.run(vim.fn.expand '%')
      end, { desc = '[T]est: run [F]ile' })
      vim.keymap.set('n', '<leader>Ta', function()
        neotest.run.run(vim.loop.cwd())
      end, { desc = '[T]est: run [A]ll in project' })
      vim.keymap.set('n', '<leader>Tl', function()
        neotest.run.run_last()
      end, { desc = '[T]est: run [L]ast' })
      vim.keymap.set('n', '<leader>Td', function()
        neotest.run.run { strategy = 'dap' }
      end, { desc = '[T]est: [D]ebug nearest' })
      vim.keymap.set('n', '<leader>TD', function()
        neotest.run.run { vim.fn.expand '%', strategy = 'dap' }
      end, { desc = '[T]est: [D]ebug file' })
      vim.keymap.set('n', '<leader>To', function()
        neotest.output.open { enter = true, auto_close = true }
      end, { desc = '[T]est: show [O]utput' })
      vim.keymap.set('n', '<leader>Tp', function()
        neotest.output_panel.toggle()
      end, { desc = '[T]est: toggle output [P]anel' })
      vim.keymap.set('n', '<leader>Ts', function()
        neotest.summary.toggle()
      end, { desc = '[T]est: toggle [S]ummary' })
    end,
  },
}
