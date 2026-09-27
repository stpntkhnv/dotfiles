local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

vim.fn.mkdir(vim.fn.stdpath 'data' .. '/site', 'p')

require('lazy').setup({
  -- Test explorer
  { import = 'plugins.tests' },

  -- Appearance
  { import = 'plugins.colorscheme' },
  { import = 'plugins.mini' }, -- statusline + text objects + surround
  { import = 'plugins.bufferline' },
  { import = 'plugins.indent' },

  -- Navigation & Search
  { import = 'plugins.telescope' },
  { import = 'plugins.sessions' },
  { import = 'plugins.file-explorer' },
  { import = 'plugins.which-key' },

  -- Editing
  { import = 'plugins.editing' },
  { import = 'plugins.treesitter' },

  -- Git
  { import = 'plugins.git' },
  { import = 'plugins.codediff' },

  -- Agents
  { import = 'plugins.agents' },
  { import = 'plugins.markdown' },

  -- LSP & Language Tools
  { import = 'plugins.mason' },
  { import = 'plugins.lsp' },
  { import = 'plugins.completion' },
  { import = 'plugins.lint' },
  { import = 'plugins.debug' },
  { import = 'plugins.csharp' },

}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})
