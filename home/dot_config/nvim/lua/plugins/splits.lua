return {
  {
    'smart-splits-nvim/smart-splits.nvim',
    lazy = false,
    init = function()
      if vim.env.HERDR_ENV ~= '1' then
        return
      end
      vim.g.smart_splits_multiplexer_integration = 'herdr'
      if vim.fn.executable(vim.env.HERDR_BIN_PATH or 'herdr') == 0 and vim.fn.executable '/run/host/usr/bin/herdr' == 1 then
        vim.env.HERDR_BIN_PATH = '/run/host/usr/bin/herdr'
      end
    end,
    opts = { at_edge = 'stop' },
    keys = {
      { '<C-h>', function() require('smart-splits').move_cursor_left() end, desc = 'Move focus left (nvim, then herdr)' },
      { '<C-j>', function() require('smart-splits').move_cursor_down() end, desc = 'Move focus down (nvim, then herdr)' },
      { '<C-k>', function() require('smart-splits').move_cursor_up() end, desc = 'Move focus up (nvim, then herdr)' },
      { '<C-l>', function() require('smart-splits').move_cursor_right() end, desc = 'Move focus right (nvim, then herdr)' },
    },
  },
}
