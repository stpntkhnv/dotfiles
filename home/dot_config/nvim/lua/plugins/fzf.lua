local function pick(name, opts)
  return function()
    require('fzf-lua')[name](opts and opts() or {})
  end
end

local function in_repo()
  return { cwd = require('repo').root() }
end

return {
  {
    'ibhagwan/fzf-lua',
    lazy = false,
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local fzf = require 'fzf-lua'
      fzf.setup { 'telescope' }
      fzf.register_ui_select()
    end,
    keys = {
      { '<leader>sh', pick 'helptags', desc = '[S]earch [H]elp' },
      { '<leader>sk', pick 'keymaps', desc = '[S]earch [K]eymaps' },
      { '<leader>sf', pick('files', in_repo), desc = '[S]earch [F]iles in repo' },
      { '<leader>sF', pick 'files', desc = '[S]earch [F]iles in cwd' },
      { '<leader>sa', pick('global', in_repo), desc = '[S]earch [A]ll: files, $buffers, @symbols, #workspace' },
      { '<leader>ss', pick 'builtin', desc = '[S]earch [S]elect picker' },
      { '<leader>sw', pick('grep_cword', in_repo), desc = '[S]earch current [W]ord in repo' },
      { '<leader>sg', pick('live_grep', in_repo), desc = '[S]earch by [G]rep in repo' },
      { '<leader>sG', pick 'live_grep', desc = '[S]earch by [G]rep in cwd' },
      { '<leader>sd', pick 'diagnostics_workspace', desc = '[S]earch [D]iagnostics' },
      { '<leader>sr', pick 'resume', desc = '[S]earch [R]esume' },
      { '<leader>s.', pick 'oldfiles', desc = '[S]earch Recent Files' },
      { '<leader>s/', pick 'lines', desc = '[S]earch [/] in Open Files' },
      { '<leader>sn', pick('files', function() return { cwd = vim.fn.stdpath 'config' } end), desc = '[S]earch [N]eovim files' },
      { '<leader><leader>', pick 'buffers', desc = '[ ] Find existing buffers' },
      { '<leader>/', pick 'blines', desc = '[/] Fuzzily search in current buffer' },
    },
  },
}
