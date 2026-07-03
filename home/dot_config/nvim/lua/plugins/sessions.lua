-- Per-directory sessions: reopen nvim in the same folder and restore the
-- exact window/buffer layout you left there.
return {
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    opts = {},
    keys = {
      {
        '<leader>qs',
        function()
          require('persistence').load()
        end,
        desc = 'Restore session for cwd',
      },
      {
        '<leader>ql',
        function()
          require('persistence').load { last = true }
        end,
        desc = 'Restore [L]ast session',
      },
      {
        '<leader>qd',
        function()
          require('persistence').stop()
        end,
        desc = "[D]on't save this session",
      },
    },
  },
}
