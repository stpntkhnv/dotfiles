local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "nvimdev/lspsaga.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons"
    },
    config = function()
      require("lspsaga").setup({})
    end
  },
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
    end
  },
  -- Подсветка и отступы
  {
    "nvim-treesitter/nvim-treesitter",
    branch = 'main',
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "bash", "json", "yaml", "c_sharp", "go" },
        highlight = { enable = true },
        indent = { enable = true },
        auto_install = true
      })
    end
  },

  -- Цветовая схема
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({ flavour = "mocha" })
      vim.cmd.colorscheme "catppuccin"
    end
  },

  -- Буферы (табы сверху)
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup()
      vim.opt.termguicolors = true
      vim.opt.showtabline = 2
    end,
  },
  require("plugins.telescope"),
  -- Автодополнение
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip"
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping.select_next_item(),
          ['<S-Tab>'] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
        })
      })
    end,
  },

  -- Расширение для go to definition и т.п. в omnisharp
  { "Hoffs/omnisharp-extended-lsp.nvim" },

  -- LSP и конфиг
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      local keymaps = require("modules.keymaps")

      local on_attach = function(_, bufnr)
        keymaps.set_dotnet_keymaps(bufnr)
      end

      -- Lua
      lspconfig.lua_ls.setup({
        settings = {
          Lua = {
            format = { enable = true }
          }
        }
      })
      -- Go
      lspconfig.gopls.setup({
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              shadow = true,
            },
            staticcheck = true,
          },
        },
      })

      -- C#
      lspconfig.omnisharp.setup({
        on_attach = on_attach,
        cmd = { "omnisharp" }, -- должен быть в $PATH
        enable_editorconfig_support = true,
        enable_ms_build_load_projects_on_demand = false,
        enable_roslyn_analyzers = true,
        organize_imports_on_format = true,
        enable_import_completion = true,
        handlers = {
          ["textDocument/definition"] = require('omnisharp_extended').handler,
        }
      })
    end
  },

  -- Mason + mason-lspconfig
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "omnisharp", "gopls" }
      })
    end
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy", -- можно заменить на "VimEnter" если хочешь сразу
    config = function()
      require("which-key").setup()
    end
  }
}
)
