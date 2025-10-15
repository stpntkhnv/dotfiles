return {
  {
    'saghen/blink.cmp',
    version = '*',
    dependencies = {
      'rafamadriz/friendly-snippets',
      {
        'L3MON4D3/LuaSnip',
        build = 'make install_jsregexp',
        config = function()
          require('luasnip.loaders.from_vscode').lazy_load()
          require('luasnip.loaders.from_snipmate').lazy_load()
          -- Load custom JSON snippets
          require('luasnip.loaders.from_vscode').lazy_load {
            paths = { vim.fn.stdpath 'config' .. '/snippets' },
          }
        end,
      },
    },
    opts = {
      keymap = {
        preset = 'default', -- 'default' | 'super-tab' | 'enter'
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-e>'] = { 'hide' },
        ['<CR>'] = { 'select_and_accept', 'fallback' },

        ['<C-p>'] = { 'select_prev', 'fallback' },
        ['<C-n>'] = { 'select_next', 'fallback' },

        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

        ['<Tab>'] = { 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
      },

      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono',
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },

      snippets = {
        preset = 'luasnip',
      },

      completion = {
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
        menu = {
          draw = {
            treesitter = { 'lsp' },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
      },

      signature = {
        enabled = true,
      },
    },
  },
}
