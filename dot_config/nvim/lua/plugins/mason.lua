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
}
