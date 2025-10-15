return {
  {
    'neovim/nvim-lspconfig',
    config = function()
      -- Configure YAML language server using new vim.lsp.config API
      vim.lsp.config('yamlls', {
        cmd = { 'yaml-language-server', '--stdio' },
        filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab' },
        root_markers = { '.git' },
        settings = {
          yaml = {
            schemas = {
              kubernetes = '*.yaml',
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

      -- Configure diagnostics display
      vim.diagnostic.config({
        virtual_text = true,  -- Show inline diagnostic messages (set to false to disable)
        signs = true,         -- Show signs in the sign column
        underline = true,     -- Underline diagnostic locations
        update_in_insert = false,  -- Don't update diagnostics while typing
        severity_sort = true, -- Sort diagnostics by severity
      })

      -- Set up LSP keybindings when LSP attaches
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('gr', vim.lsp.buf.references, '[G]oto [R]eferences')
          map('gi', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
          map('gt', vim.lsp.buf.type_definition, '[G]oto [T]ype Definition')
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
          map('K', vim.lsp.buf.hover, 'Hover Documentation')
          map('<leader>k', vim.lsp.buf.hover, 'Hover Documentation (alt)')
          map('<leader>ds', vim.lsp.buf.document_symbol, '[D]ocument [S]ymbols')
          map('<leader>ws', vim.lsp.buf.workspace_symbol, '[W]orkspace [S]ymbols')
        end,
      })

      -- Global keybinding to toggle inline diagnostics
      vim.keymap.set('n', '<leader>td', function()
        local config = vim.diagnostic.config()
        vim.diagnostic.config({ virtual_text = not config.virtual_text })
      end, { desc = '[T]oggle [D]iagnostics inline' })
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
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        yaml = { 'prettier' },
        yml = { 'prettier' },
      },
    },
  },
}
