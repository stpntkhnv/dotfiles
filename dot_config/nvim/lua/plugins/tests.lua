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

      vim.keymap.set('n', '<leader>tn', function()
        neotest.run.run()
      end, { desc = 'Run nearest test' })
      vim.keymap.set('n', '<leader>tf', function()
        neotest.run.run(vim.fn.expand '%')
      end, { desc = 'Run tests in file' })
      vim.keymap.set('n', '<leader>ts', function()
        neotest.run.run(vim.loop.cwd())
      end, { desc = 'Run all tests in project' })
      vim.keymap.set('n', '<leader>tl', function()
        neotest.run.run_last()
      end, { desc = 'Run last test' })
      vim.keymap.set('n', '<leader>td', function()
        neotest.run.run { strategy = 'dap' }
      end, { desc = 'Debug nearest test' })
      vim.keymap.set('n', '<leader>tD', function()
        neotest.run.run { vim.fn.expand '%', strategy = 'dap' }
      end, { desc = 'Debug tests in file' })
      vim.keymap.set('n', '<leader>to', function()
        neotest.output.open { enter = true, auto_close = true }
      end, { desc = 'Show test output' })
      vim.keymap.set('n', '<leader>tp', function()
        neotest.output_panel.toggle()
      end, { desc = 'Toggle output panel' })
      vim.keymap.set('n', '<leader>tsu', function()
        neotest.summary.toggle()
      end, { desc = 'Toggle test summary' })
    end,
  },
}
