vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  desc = 'Auto-reload files changed outside Neovim',
  group = vim.api.nvim_create_augroup('auto-reload', { clear = true }),
  callback = function()
    if vim.fn.mode() ~= 'c' then
      vim.cmd('checktime')
    end
  end,
})

-- C# namespace detection helper
local function get_csharp_namespace()
  local filepath = vim.fn.expand '%:p'
  local dir = vim.fn.fnamemodify(filepath, ':h')
  local filename = vim.fn.expand '%:t:r'

  -- Default to filename if no project found
  local namespace = filename
  local root_dir = dir

  -- Search up for .csproj file
  local max_depth = 10
  local depth = 0
  while root_dir ~= '/' and root_dir ~= '' and depth < max_depth do
    local csproj_files = vim.fn.glob(root_dir .. '/*.csproj', false, true)
    if #csproj_files > 0 then
      local project_name = vim.fn.fnamemodify(csproj_files[1], ':t:r')
      local relative_path = dir:gsub(vim.pesc(root_dir), '')
      relative_path = relative_path:gsub('^/', ''):gsub('/', '.')

      if relative_path ~= '' then
        namespace = project_name .. relative_path
      else
        namespace = project_name
      end
      break
    end
    root_dir = vim.fn.fnamemodify(root_dir, ':h')
    depth = depth + 1
  end

  return namespace
end

-- Make function globally available for snippets
_G.get_csharp_namespace = get_csharp_namespace

-- C# file template with namespace detection
vim.api.nvim_create_autocmd('BufNewFile', {
  desc = 'C# file template with namespace',
  group = vim.api.nvim_create_augroup('csharp-template', { clear = true }),
  pattern = '*.cs',
  callback = function()
    -- Wait a bit for buffer to be fully initialized
    vim.defer_fn(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

      -- Only insert template if buffer is empty
      if #lines == 1 and lines[1] == '' then
        local namespace = get_csharp_namespace()
        local filename = vim.fn.expand '%:t:r'

        local template = {
          'namespace ' .. namespace .. ';',
          '',
          'public class ' .. filename,
          '{',
          '  ',
          '}',
        }

        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, template)
        vim.api.nvim_win_set_cursor(0, { 5, 2 }) -- Position cursor inside class
      end
    end, 50)
  end,
})
