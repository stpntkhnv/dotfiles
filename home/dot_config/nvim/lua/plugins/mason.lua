return {
  {
    'mason-org/mason.nvim',
    config = function()
      require('mason').setup {
        registries = {
          'github:mason-org/mason-registry',
          'github:Crashdummyy/mason-registry', -- For Roslyn language server
        },
      }
    end,
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    config = function()
      require('mason-lspconfig').setup {
        ensure_installed = {},
        automatic_installation = false,
      }
    end,
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    config = function()
      require('mason-tool-installer').setup {
        ensure_installed = {
          'lua-language-server',
          'yaml-language-server',
          'roslyn', -- C# LSP, from the Crashdummyy registry
          'stylua',
          'prettier',
          'markdownlint',
          'netcoredbg',
          'delve',
        },
      }
    end,
  },
}
