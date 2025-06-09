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
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup()
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
    branch = 'master',
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "bash", "json", "yaml", "c_sharp", "go", "gitignore" },
        sync_install = false,
        auto_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end
  },
  {
    "aznhe21/actions-preview.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("actions-preview").setup()
    end,
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
      local keymaps = require("modules.keymaps")

      -- общий on_attach (у тебя только для C#)
      local function on_attach(client, bufnr)
        if client.name == "omnisharp" then
          keymaps.set_dotnet_keymaps(bufnr)
        end
      end

      -- Просто кладём настройки в кэш Neovim
      vim.lsp.config("lua_ls", {
        settings = { Lua = { format = { enable = true } } },
      })

      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            analyses = { unusedparams = true, shadow = true },
            staticcheck = true,
          },
        },
      })

      vim.lsp.config("omnisharp", {
        on_attach = on_attach,
        enable_roslyn_analyzers = true,
        organize_imports_on_format = true,
        handlers = {
          ["textDocument/definition"] =
              require("omnisharp_extended").handler,
        },
      })
    end,
  },
  -- Mason + mason-lspconfig
  {
    "williamboman/mason.nvim",
    opts = {}, -- v2 syntax, одного require достаточно
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = { -- то же самое, opts вместо config
      ensure_installed = { "lua_ls", "gopls", "omnisharp" },
      -- automatic_enable = true -- по умолчанию уже так
    },
  },
  {
    "folke/which-key.nvim",
    event = "VimEnter", -- можно заменить на "VimEnter" если хочешь сразу
    config = function()
      require("which-key").setup()
    end
  }
}
)

require("modules.autocommands").setup()
require("modules.usercommands").setup()
require("modules.options").setup()
require("modules.keymaps").setup()
