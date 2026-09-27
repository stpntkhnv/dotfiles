return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = 'markdown',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = {
      ignore = function(buf)
        return vim.api.nvim_buf_get_name(buf):match '^%a+://' ~= nil
      end,
    },
    config = function(_, opts)
      local rm = require 'render-markdown'
      rm.setup(opts)
      local diff_tabs, disabled = {}, {}
      local group = vim.api.nvim_create_augroup('render-markdown-codediff', { clear = true })
      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'CodeDiffOpen',
        callback = function(ev)
          diff_tabs[ev.data.tabpage] = true
        end,
      })
      vim.api.nvim_create_autocmd({ 'BufWinEnter', 'FileType' }, {
        group = group,
        callback = function(args)
          if diff_tabs[vim.api.nvim_get_current_tabpage()] and vim.bo[args.buf].filetype == 'markdown' and not disabled[args.buf] then
            disabled[args.buf] = true
            vim.api.nvim_buf_call(args.buf, rm.buf_disable)
            vim.schedule(function()
              if vim.api.nvim_buf_is_valid(args.buf) then
                vim.api.nvim_buf_clear_namespace(args.buf, vim.api.nvim_create_namespace 'render-markdown.nvim', 0, -1)
              end
            end)
          end
        end,
      })
      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'CodeDiffClose',
        callback = function(ev)
          diff_tabs[ev.data.tabpage] = nil
          for buf in pairs(disabled) do
            if vim.api.nvim_buf_is_valid(buf) then
              vim.api.nvim_buf_call(buf, rm.buf_enable)
            end
          end
          disabled = {}
        end,
      })
    end,
    keys = {
      { '<leader>tm', '<cmd>RenderMarkdown buf_toggle<cr>', ft = 'markdown', desc = '[T]oggle [M]arkdown rendering' },
    },
  },
}
