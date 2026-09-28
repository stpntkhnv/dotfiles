local function repo_root()
  local file = vim.api.nvim_buf_get_name(0)
  local dir = (vim.bo.buftype == '' and file ~= '') and vim.fs.dirname(file) or vim.fn.getcwd()
  return vim.fs.root(dir, '.git') or dir
end

local function open_explorer()
  local root = repo_root()
  if vim.t.dotnet_tree_root ~= root then
    local manager = require 'neo-tree.sources.manager'
    manager.close 'dotnet-tree'
    manager.dispose('dotnet-tree', vim.api.nvim_get_current_tabpage())
    manager.get_state('dotnet-tree').path = root
    vim.t.dotnet_tree_root = root
  end
  if #vim.fn.globpath(root, '*.sln', false, true) + #vim.fn.globpath(root, '*.slnx', false, true) > 0 then
    vim.cmd 'Neotree dotnet-tree reveal'
  else
    vim.cmd 'Neotree filesystem reveal'
  end
end

return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
      'alessandropietrobelli/dotnet-tree.nvim',
    },
    lazy = false,
    keys = {
      { '\\', open_explorer, desc = 'Explorer: solution or files' },
    },
    opts = {
      sources = { 'filesystem', 'buffers', 'git_status', 'dotnet-tree' },
      default_source = 'filesystem',
      source_selector = {
        winbar = true,
        sources = {
          { source = 'dotnet-tree', display_name = ' 󰘐 .NET ' },
          { source = 'filesystem', display_name = '  Files ' },
        },
      },
      ['dotnet-tree'] = {
        window = {
          mappings = {
            ['\\'] = 'close_window',
          },
        },
      },
      filesystem = {
        filtered_items = {
          visible = true,  -- Show hidden files by default
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        follow_current_file = {
          enabled = true,
        },
        use_libuv_file_watcher = true,  -- Auto-refresh on external changes
        window = {
          mappings = {
            ['\\'] = 'close_window',
          },
        },
      },
      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            vim.cmd('setlocal relativenumber')
          end,
        },
      },
    },
  },
}
