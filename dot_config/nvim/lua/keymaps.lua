vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Buffer navigation
vim.keymap.set('n', '<Tab>', '<cmd>BufferLineCycleNext<CR>', { desc = 'Next buffer tab' })
vim.keymap.set('n', '<S-Tab>', '<cmd>BufferLineCyclePrev<CR>', { desc = 'Previous buffer tab' })
vim.keymap.set('n', '<leader>bn', '<cmd>BufferLineCycleNext<CR>', { desc = '[B]uffer [N]ext' })
vim.keymap.set('n', '<leader>bp', '<cmd>BufferLineCyclePrev<CR>', { desc = '[B]uffer [P]revious' })

-- Buffer closing (smart close that preserves window layout)
local function smart_close_buffer(force)
  local bufnr = vim.api.nvim_get_current_buf()
  local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')

  -- Don't close special buffers like NeoTree
  if buftype ~= '' then
    vim.cmd('close')
    return
  end

  -- Try to switch to alternate buffer first
  if vim.fn.bufnr('#') ~= -1 and vim.fn.bufnr('#') ~= bufnr then
    vim.cmd('buffer #')
  else
    vim.cmd('BufferLineCycleNext')
  end

  -- Delete the buffer
  local cmd = force and 'bd!' or 'bd'
  pcall(vim.cmd, cmd .. ' ' .. bufnr)
end

vim.keymap.set('n', '<leader>x', function() smart_close_buffer(false) end, { desc = 'Close buffer' })
vim.keymap.set('n', '<leader>bd', function() smart_close_buffer(false) end, { desc = '[B]uffer [D]elete' })
vim.keymap.set('n', '<leader>bD', function() smart_close_buffer(true) end, { desc = '[B]uffer [D]elete (force)' })
vim.keymap.set('n', '<leader>bw', '<cmd>bw<CR>', { desc = '[B]uffer [W]ipeout' })

-- Close other buffers
vim.keymap.set('n', '<leader>bo', '<cmd>BufferLineCloseOthers<CR>', { desc = '[B]uffer close [O]thers' })
vim.keymap.set('n', '<leader>bl', '<cmd>BufferLineCloseLeft<CR>', { desc = '[B]uffer close [L]eft' })
vim.keymap.set('n', '<leader>br', '<cmd>BufferLineCloseRight<CR>', { desc = '[B]uffer close [R]ight' })

-- Pin/unpin buffer
vim.keymap.set('n', '<leader>bP', '<cmd>BufferLineTogglePin<CR>', { desc = '[B]uffer toggle [P]in' })

-- Pick buffer
vim.keymap.set('n', '<leader>bb', '<cmd>BufferLinePick<CR>', { desc = '[B]uffer pick' })

-- Go to buffer by number
for i = 1, 9 do
  vim.keymap.set('n', '<leader>' .. i, '<cmd>BufferLineGoToBuffer ' .. i .. '<CR>', { desc = 'Go to buffer ' .. i })
end
