---
covers:
  features: [neovim]
  paths:
    - home/dot_config/nvim/**
---

# Neovim

## What it does

Feature `neovim` (`scope: both`, default on): `neovim` and `tree-sitter-cli`
from pacman plus the config tree, which `.chezmoiignore` drops whole when the
feature is off. This doc holds the general config; C# is
[neovim-csharp.md](neovim-csharp.md), agent tooling
[neovim-agents.md](neovim-agents.md).

## Files

| Path | Role |
|---|---|
| `home/dot_config/nvim/**` | 34 files. `init.lua` loads `lua/{options,keymaps,autocmds,plugins}.lua`; one lazy.nvim spec per file in `lua/plugins/`. `lazy-lock.json` pins every plugin and moves when lazy installs, cleans or updates one |
| `.../lua/repo.lua` | `root()`: git root of the current file, else cwd; used by search, explorer, grug-far |
| `.../lua/plugins/mason.lua` | adds `Crashdummyy/mason-registry`: its `roslyn` meets roslyn.nvim's minimum server version, mason-org's `roslyn-language-server` did not (2026-09-27) |

## How it works

- Search (`fzf.lua`, fzf-lua, `telescope` profile, also `vim.ui.select`):
  `<leader>sf` / `sg` / `sw` in the current file's repo, `sF` / `sG` in cwd,
  `<leader>sa` everything (files, `$`buffers, `@`symbols, `#`workspace).
  `<leader>sR` replaces across the repo (grug-far).
- LSP maps (`lsp.lua`, `LspAttach`): fzf-lua pickers on nvim's own `grr` `gri`
  `grt`; `gd`, `gD` stay. Folds come from LSP `foldingRange` where offered,
  else treesitter (`options.lua`); all open (`foldlevelstart = 99`).
- Diagnostics: the cursor line shows the full message below it
  (`virtual_lines`), other lines the short tail; `<leader>di` toggles both.
  `LspProgress` becomes nvim progress messages (Roslyn: 29 on one load);
  `percent` is floored, nvim 0.12 rejects a float. LSP folds skip a window
  whose `foldexpr` is not the global one (CodeDiff compact mode).
- Messages: ui2 (`options.lua`) - no "Press ENTER" (verified in a TUI,
  2026-09-28).
- Motion: `s` / `S` flash jump / treesitter select; surround moved to `gsa`
  `gsd` `gsr`. mini.ai `af`/`if` method and `ac`/`ic` class from treesitter
  (`F` = the old function call), `]m` / `[m` move by method
  (nvim-treesitter-textobjects). Sticky class/method header:
  treesitter-context, `<leader>tc`. `<leader>tu` undotree.
- Windows: `Ctrl-h/j/k/l` via smart-splits; at an nvim edge it asks herdr to
  focus the neighbour pane.
- Treesitter runs the `main` branch (`treesitter.lua`): the listed parsers
  install at startup (`ts.install {`), any other on its first `FileType`, and
  highlighting starts per buffer.
- Completion: blink.cmp + LuaSnip (`completion.lua`); conform formats on save
  (`lsp.lua`), falling back to the LSP formatter.

## Constraints

- `lua/plugins.lua` creates `~/.local/share/nvim/site` before lazy.nvim starts:
  on a first run lazy drops the missing dir from `rtp`, and the parsers
  nvim-treesitter installs there fail to load until restart
  ([workarounds.md](workarounds.md), lazy.nvim#2153).
- `packadd nvim.undotree` runs inside the `<leader>tu` key: from `options.lua`
  it ran before lazy's `performance.rtp.reset` rebuilt `rtp` to a fixed list,
  which dropped the pack dir and left `:Undotree` without its Lua module.
- `indentexpr` from nvim-treesitter only where the language has an `indents`
  query (`treesitter.lua`, `start()`): `c_sharp` has none, and that indentexpr
  put the line after `{` at column 0. C# keeps the runtime `GetCSIndent`.
- No `gr`, `gi`, `gt` maps (`lsp.lua`, `LspAttach`): a buffer-local `gr`
  waited `timeoutlen` for nvim's default `grn`/`grr`/..., `gi`/`gt` shadowed
  builtins.
- yamlls (`lsp.lua`, `vim.lsp.config('yamlls'`) has no catch-all `kubernetes = '*.yaml'`: no manifests in
  the work repos, and it put false errors on `compose.yaml` (2) and an Azure
  pipeline (6), 2026-09-27. yamlls pulls SchemaStore by itself.
- No mason-lspconfig: v2 auto-enabled every mason server and started
  `stylua --lsp` beside conform. `lsp.lua` enables `lua_ls`, `yamlls`,
  `jsonls`; roslyn.nvim enables `roslyn`.
- smart-splits crosses only nvim -> herdr: for a context pane herdr's
  `process-info` sees `distrobox,podman`, never nvim, so its herdr-side plugin
  would steal the keys. `splits.lua` `init` points `HERDR_BIN_PATH` at
  `/run/host/usr/bin/herdr` when the inherited one is not executable (the host
  path, absent in a context). herdr moves UI focus, so it acts only from the
  pane you are looking at. `at_edge = 'stop'`: with no pane there the key
  stops, as the old `wincmd` maps did.
- ui2 is `vim._core` (experimental), enabled under `pcall`.
- flash's char mode is off: `f`/`t` stay builtin.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| fzf-lua, 2026-09-28 | external fzf process, `global` picker, lighter under the 8g cap | telescope |
| flash on `s`, surround on `gs`, 2026-09-28 | one-key jump; LazyVim's layout | flash on `S` or `<CR>` |
| kulala.nvim dropped, 2026-09-27 | upstream repo went private (404) | 1-star recovery fork |

## Verify

```sh
git ls-files -- 'home/dot_config/nvim/**' | wc -l   # 34
# in nvim: :lua =vim.diagnostic.config().virtual_lines   -> { current_line = true }
#          :lua =debug.getinfo(vim.ui.select).source      -> .../fzf-lua/...
```

## See also

- [neovim-csharp.md](neovim-csharp.md), [neovim-agents.md](neovim-agents.md).
- [dev-tools.md](dev-tools.md) - the other editors and SDKs.
- [workarounds.md](workarounds.md) - the lazy.nvim row.
