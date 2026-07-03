return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main', -- rewrite that replaced the old 'master'; module nvim-treesitter.configs is gone
    lazy = false,
    build = ':TSUpdate',
    config = function()
      local ts = require 'nvim-treesitter'
      ts.setup {}

      -- stylua: ignore
      ts.install {
        -- kickstart defaults
        'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc',
        -- the actual working stack: .NET, containers, configs
        'c_sharp', 'json', 'xml', 'yaml', 'toml', 'go', 'gomod', 'dockerfile', 'gitcommit', 'git_rebase', 'http', 'sql',
      }

      -- The main branch no longer starts highlighting itself: enable it per
      -- buffer, auto-installing missing parsers (replaces auto_install=true).
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if not lang then
            return
          end
          local function start()
            if not vim.api.nvim_buf_is_valid(args.buf) then
              return
            end
            vim.treesitter.start(args.buf, lang)
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
          if vim.treesitter.language.add(lang) then
            start()
          elseif vim.tbl_contains(ts.get_available(), lang) then
            ts.install(lang):await(start)
          end
        end,
      })
    end,
  },
  {
    'NMAC427/guess-indent.nvim',
  },
}
