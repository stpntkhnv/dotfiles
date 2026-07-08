-- Whole-branch review before commit/push: a file tree of every change with
-- side-by-side diffs, which lazygit/gitsigns don't give in one view.
--
-- Every mapping targets the repo of the CURRENT FILE, not cwd: with an
-- umbrella folder holding many repos, cwd is rarely the repo you're editing
-- (same reason git.lua uses LazyGitCurrentFile). We resolve that repo's
-- toplevel and pass it to Diffview with -C.
local function file_git_root()
  local file = vim.api.nvim_buf_get_name(0)
  local dir = file ~= '' and vim.fn.fnamemodify(file, ':h') or vim.fn.getcwd()
  local root = vim.fn.systemlist({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' })[1]
  if vim.v.shell_error ~= 0 or not root or root == '' then
    vim.notify('Not inside a git repository', vim.log.levels.WARN)
    return nil
  end
  return root
end

local function open(rev)
  local root = file_git_root()
  if not root then
    return
  end
  vim.cmd('DiffviewOpen -C' .. root .. (rev and (' ' .. rev) or ''))
end

-- Base for branch review: prefer the upstream tracking branch, so base...HEAD
-- is exactly what a push would send. Fall back to origin's default branch,
-- then main/master.
local function branch_base(root)
  local function git(...)
    local cmd = { 'git', '-C', root }
    for _, a in ipairs { ... } do
      cmd[#cmd + 1] = a
    end
    local out = vim.fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 or not out[1] or out[1] == '' then
      return nil
    end
    return out[1]
  end

  local up = git('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}')
  if up then
    return up
  end
  local head = git('symbolic-ref', '--short', 'refs/remotes/origin/HEAD')
  if head then
    return head
  end
  for _, b in ipairs { 'origin/main', 'origin/master', 'main', 'master' } do
    if git('rev-parse', '--verify', '--quiet', b) then
      return b
    end
  end
  return nil
end

local function review_branch()
  local root = file_git_root()
  if not root then
    return
  end
  local base = branch_base(root)
  if not base then
    vim.notify('Could not resolve a base branch to review against', vim.log.levels.WARN)
    return
  end
  vim.cmd('DiffviewOpen -C' .. root .. ' ' .. base .. '...HEAD')
end

return {
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory', 'DiffviewToggleFiles' },
    keys = {
      { '<leader>gd', function() open() end, desc = '[G]it [D]iff (working tree)' },
      { '<leader>gr', review_branch, desc = '[G]it [R]eview branch vs base' },
      { '<leader>gf', '<cmd>DiffviewFileHistory %<cr>', desc = '[G]it [F]ile history' },
      { '<leader>gF', '<cmd>DiffviewFileHistory<cr>', desc = '[G]it repo [F]ile history' },
      { '<leader>gc', '<cmd>DiffviewClose<cr>', desc = '[G]it diff [C]lose' },
    },
    opts = {
      enhanced_diff_hl = true,
    },
  },
}
