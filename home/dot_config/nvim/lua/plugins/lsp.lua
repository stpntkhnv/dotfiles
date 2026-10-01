local function csharpier_root(file)
  local root = vim.fs.root(file, '.git') or vim.fs.dirname(file)
  for _, manifest in ipairs { root .. '/.config/dotnet-tools.json', root .. '/dotnet-tools.json' } do
    if vim.uv.fs_stat(manifest) and table.concat(vim.fn.readfile(manifest), '\n'):find('"csharpier"', 1, true) then
      return root, true
    end
  end
  local rc = vim.fs.find(function(name)
    return name:match '^%.csharpierrc' ~= nil
  end, { path = vim.fs.dirname(file), upward = true, stop = vim.fs.dirname(root) })[1]
  if rc then
    return root, false
  end
end

local function align_codelens_to_indent()
  require 'vim.lsp.codelens'
  local provider = require('vim.lsp._capability').all.codelens
  if not (provider and provider.on_win) then
    vim.notify('codelens: nvim internals changed, lenses stay at the symbol column', vim.log.levels.WARN)
    return
  end
  local on_win = provider.on_win
  provider.on_win = function(self, toprow, botrow)
    local lsp_range = vim.range.lsp
    vim.range.lsp = function(buf, range, encoding)
      local r = lsp_range(buf, range, encoding)
      local line = vim.api.nvim_buf_get_lines(buf, r.start_row, r.start_row + 1, false)[1] or ''
      return vim.range(buf, r.start_row, vim.fn.strdisplaywidth(line:match '^%s*'), r.end_row, r.end_col)
    end
    local ok, err = pcall(on_win, self, toprow, botrow)
    vim.range.lsp = lsp_range
    if not ok then
      error(err, 0)
    end
  end
end

return {
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'b0o/SchemaStore.nvim' },
    config = function()
      -- Configure YAML language server using new vim.lsp.config API
      vim.lsp.config('yamlls', {
        cmd = { 'yaml-language-server', '--stdio' },
        filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab' },
        root_markers = { '.git' },
        settings = {
          yaml = {
            schemas = {
              ['http://json.schemastore.org/github-workflow'] = '.github/workflows/*',
              ['http://json.schemastore.org/github-action'] = '.github/action.{yml,yaml}',
              ['http://json.schemastore.org/ansible-stable-2.9'] = 'roles/tasks/*.{yml,yaml}',
              ['http://json.schemastore.org/prettierrc'] = '.prettierrc.{yml,yaml}',
              ['http://json.schemastore.org/kustomization'] = 'kustomization.{yml,yaml}',
              ['http://json.schemastore.org/ansible-playbook'] = '*play*.{yml,yaml}',
              ['http://json.schemastore.org/chart'] = 'Chart.{yml,yaml}',
              ['https://json.schemastore.org/dependabot-v2'] = '.github/dependabot.{yml,yaml}',
              ['https://json.schemastore.org/gitlab-ci'] = '*gitlab-ci*.{yml,yaml}',
              ['https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json'] = '*api*.{yml,yaml}',
            },
            format = { enable = true },
            validate = true,
            completion = true,
            hover = true,
          },
        },
      })

      vim.lsp.enable('yamlls')

      -- Lua LSP for editing this config; lazydev provides the vim/nvim library
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            completion = { callSnippet = 'Replace' },
          },
        },
      })
      vim.lsp.enable('lua_ls')

      local schemastore = require 'schemastore'
      local ok, schemas = pcall(schemastore.json.schemas, {
        replace = {
          ['launchsettings.json'] = {
            description = 'ASP.NET launchSettings.json',
            fileMatch = { 'launchSettings.json', 'launchsettings.json' },
            name = 'launchsettings.json',
            url = 'https://www.schemastore.org/launchsettings.json',
          },
        },
      })
      vim.lsp.config('jsonls', {
        init_options = { provideFormatter = false },
        settings = {
          json = {
            schemas = ok and schemas or schemastore.json.schemas(),
            validate = { enable = true },
          },
        },
      })
      vim.lsp.enable('jsonls')

      -- Configure diagnostics display: the cursor line shows the full message
      -- below it, every other line keeps the short one at the end.
      local inline = { virtual_text = { current_line = false }, virtual_lines = { current_line = true } }
      vim.diagnostic.config(vim.tbl_extend('force', {
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      }, inline))

      vim.api.nvim_create_autocmd('LspProgress', {
        group = vim.api.nvim_create_augroup('lsp-progress', { clear = true }),
        callback = function(ev)
          local value = ev.data.params.value
          if type(value) ~= 'table' then
            return
          end
          vim.api.nvim_echo({ { value.message or value.title or 'done' } }, false, {
            id = 'lsp.' .. ev.data.client_id .. '.' .. tostring(ev.data.params.token),
            kind = 'progress',
            source = 'vim.lsp',
            title = value.title,
            status = value.kind ~= 'end' and 'running' or 'success',
            percent = value.percentage and math.floor(value.percentage) or nil,
          })
        end,
      })

      -- Set up LSP keybindings when LSP attaches
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- fzf-lua pickers instead of the quickfix-based vim.lsp.buf
          -- equivalents: live filtering + preview, and workspace symbols
          -- search the whole solution.
          local fzf = require 'fzf-lua'
          map('gd', fzf.lsp_definitions, '[G]oto [D]efinition')
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('grr', fzf.lsp_references, '[G]oto [R]eferences')
          map('gri', fzf.lsp_implementations, '[G]oto [I]mplementation')
          map('grt', fzf.lsp_typedefs, '[G]oto [T]ype Definition')
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
          map('K', vim.lsp.buf.hover, 'Hover Documentation')
          map('<leader>k', vim.lsp.buf.hover, 'Hover Documentation (alt)')
          map('<leader>ds', fzf.lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>ws', fzf.lsp_live_workspace_symbols, '[W]orkspace [S]ymbols')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/foldingRange') then
            local win = vim.fn.bufwinid(event.buf)
            if win ~= -1 and vim.wo[win].foldexpr == vim.go.foldexpr then
              vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
            end
          end
          if client and client.name == 'roslyn' and client:supports_method('textDocument/codeLens') then
            vim.lsp.codelens.enable(true, { bufnr = event.buf })
          end
        end,
      })

      -- Global keybinding to toggle inline diagnostics
      vim.keymap.set('n', '<leader>di', function()
        if vim.diagnostic.config().virtual_text then
          vim.diagnostic.config { virtual_text = false, virtual_lines = false }
        else
          vim.diagnostic.config(inline)
        end
      end, { desc = '[D]iagnostics toggle [I]nline' })

      -- Inlay hints: roslyn is configured to serve them (see csharp.lua),
      -- the client side is one switch for every buffer.
      vim.lsp.inlay_hint.enable(true)
      vim.keymap.set('n', '<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end, { desc = '[T]oggle inlay [H]ints' })

      align_codelens_to_indent()
    end,
  },
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = vim.bo[bufnr].filetype == 'cs' and 3000 or 500,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        yaml = { 'prettier' },
        cs = { 'csharpier' },
      },
      formatters = {
        csharpier = {
          condition = function(_, ctx)
            return csharpier_root(ctx.filename) ~= nil
          end,
          command = function(_, ctx)
            local _, tool = csharpier_root(ctx.filename)
            return tool and 'dotnet' or 'csharpier'
          end,
          args = function(_, ctx)
            local _, tool = csharpier_root(ctx.filename)
            return tool and { 'csharpier', 'format', '--stdin-path', '$FILENAME' } or { 'format', '--stdin-path', '$FILENAME' }
          end,
          cwd = function(_, ctx)
            return (csharpier_root(ctx.filename))
          end,
        },
      },
    },
  },
}
