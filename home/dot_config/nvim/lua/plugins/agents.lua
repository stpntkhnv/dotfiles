local function share_claude_ide_dir()
  local home = vim.uv.os_homedir()
  local shared = home .. '/.claude/ide'
  vim.fn.mkdir(shared, 'p')
  for _, dir in ipairs(vim.fn.glob(home .. '/.claude-*', false, true)) do
    local ide = dir .. '/ide'
    if vim.fn.isdirectory(dir) == 1 and not vim.uv.fs_lstat(ide) then
      vim.uv.fs_symlink(shared, ide)
    end
  end
end

local function tree_add()
  if vim.b.neo_tree_source ~= 'dotnet-tree' then
    return vim.cmd 'ClaudeCodeTreeAdd'
  end
  local node = require('neo-tree.sources.manager').get_state('dotnet-tree').tree:get_node()
  if node and node.path then
    require('claudecode').send_at_mention(node.path)
  end
end

return {
  {
    'coder/claudecode.nvim',
    event = 'VeryLazy',
    cmd = { 'ClaudeCodeAdd', 'ClaudeCodeSend', 'ClaudeCodeTreeAdd', 'ClaudeCodeStatus', 'ClaudeCodeDiffAccept', 'ClaudeCodeDiffDeny', 'ClaudeCodeCloseAllDiffs' },
    init = share_claude_ide_dir,
    opts = {
      terminal = { provider = 'none' },
      diff_opts = { open_in_new_tab = true },
    },
    config = function(_, opts)
      local claudecode = require 'claudecode'
      claudecode.setup(opts)
      local format = claudecode._format_path_for_at_mention
      claudecode._format_path_for_at_mention = function(path)
        local _, is_dir = format(path)
        return vim.fn.fnamemodify(path, ':p'), is_dir
      end
    end,
    keys = {
      { '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Claude: add current file' },
      { '<leader>as', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = 'Claude: send selection' },
      { '<leader>as', tree_add, ft = 'neo-tree', desc = 'Claude: add node' },
      { '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Claude: accept diff' },
      { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Claude: deny diff' },
    },
  },
}
