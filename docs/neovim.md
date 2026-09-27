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
feature is off. The config is tuned for C#/.NET through Roslyn and for code
that agents write in the pane next to nvim.

## Files

| Path | Role |
|---|---|
| `home/dot_config/nvim/**` | 29 files. `init.lua` loads `lua/{options,keymaps,autocmds,plugins}.lua`; one lazy.nvim spec per file in `lua/plugins/`. `lazy-lock.json` pins every plugin and moves when lazy installs, cleans or updates one |
| `.../lua/plugins/mason.lua` | adds `Crashdummyy/mason-registry`: its `roslyn` meets roslyn.nvim's minimum server version, mason-org's `roslyn-language-server` did not (2026-09-27) |
| `.../private_snippets/{cs.json,package.json}` | deployed as `snippets/`; LuaSnip's vscode loader reads a directory only through its `package.json` |

## How it works

- C#: roslyn.nvim (`lua/plugins/csharp.lua`), blink.cmp + LuaSnip, conform
  (format on save falls back to Roslyn), nvim-dap + netcoredbg
  (`debug.lua`), neotest-vstest (`tests.lua`).
- LSP maps (`lsp.lua`, `LspAttach`): Telescope pickers sit on nvim's own
  `grr` `gri` `grt`; `gd` and `gD` stay.
- Treesitter runs the `main` branch (`treesitter.lua`): the listed parsers
  install at startup (`ts.install {`), any other on its first `FileType`, and
  highlighting starts per buffer.
- Files edited by agents: `lua/autocmds.lua` runs `checktime` on focus, buffer
  enter, cursor hold and a 1 s timer in normal mode, so a clean buffer reloads
  without a keypress; a buffer with unsaved edits gets nvim's W12 prompt
  instead. Roslyn sees unopened files on its own: nvim 0.12 does not offer
  `didChangeWatchedFiles` on Linux, and roslyn watches the disk itself
  (verified 2026-09-27, a new class seen without restart).

## Constraints

- `lua/plugins.lua` creates `~/.local/share/nvim/site` before lazy.nvim starts:
  on a first run lazy drops the missing dir from `rtp`, and the parsers
  nvim-treesitter installs there fail to load until restart
  ([workarounds.md](workarounds.md), lazy.nvim#2153).
- roslyn settings live in the spec's `init`, not `config`: roslyn.nvim's
  `plugin/roslyn.lua` calls `vim.lsp.enable("roslyn")` when the plugin loads,
  before `config` runs, so the client started without them (inlay hints: 0
  before the move, 2 after, 2026-09-27).
- `ROSLYN_LANGUAGE_SERVER_DAEMON_KEEPALIVE=0`, same `init`: roslyn.nvim newer
  than the pinned `c4ef259` starts the server in daemon mode, alive 900 s after
  the last client - a solution-sized process left under the 8g container cap.
- `indentexpr` from nvim-treesitter only where the language has an `indents`
  query (`treesitter.lua`, `start()`): `c_sharp` has none, and that indentexpr put the line after `{` at
  column 0. C# keeps the runtime `GetCSIndent`.
- No `gr`, `gi`, `gt` maps (`lsp.lua`, `LspAttach`): a buffer-local `gr` waited `timeoutlen` for nvim's
  default `grn`/`grr`/..., and `gi`/`gt` shadowed builtins.
- yamlls (`lsp.lua`, `vim.lsp.config('yamlls'`) has no catch-all
  `kubernetes = '*.yaml'`: the work repos hold no manifests, and it put false
  errors on `compose.yaml` (2) and an Azure pipeline (6), 2026-09-27. yamlls
  pulls SchemaStore by itself.
- No mason-lspconfig: v2 auto-enabled every mason server and started
  `stylua --lsp` as a second Lua client beside conform. `lsp.lua` enables
  `lua_ls` and `yamlls`, roslyn.nvim enables `roslyn`.
- Tests: neotest-vstest speaks Microsoft Testing Platform (xUnit v3, 10/10 on
  2026-09-27). `broad_recursive_discovery` is off: a folder of many repos would
  freeze nvim.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| neotest-vstest, 2026-09-27 | neotest-dotnet discovery crashes on nvim 0.12 (`get_node_text`, `attempt to call method 'start'`), unmaintained since 2025-09 | easy-dotnet test runner (starts its own Roslyn) |
| diffview-plus.nvim, 2026-09-27 | `sindrets/diffview.nvim` has had no push since 2024-08-02; the fork keeps the `diffview` module and `:Diffview*` commands | keeping the original |
| kulala.nvim dropped, 2026-09-27 | upstream repo went private (404) | 1-star recovery fork |

## Verify

```sh
git ls-files -- 'home/dot_config/nvim/**' | wc -l   # 29
# in a context, inside a solution, a .cs buffer:
#   :lua print(vim.bo.indentexpr)                      -> GetCSIndent(v:lnum)
#   :lua =vim.lsp.get_clients({name='roslyn'})[1].settings  -> has csharp|inlay_hints
#   :lua =vim.tbl_map(function(s) return s.trigger end, require('luasnip').get_snippets('cs'))  -> includes recordp
```

## See also

- [dev-tools.md](dev-tools.md) - the other editors and SDKs.
- [multiplexer.md](multiplexer.md) - tmux `focus-events`, which lets
  `FocusGained` reach nvim.
- [workarounds.md](workarounds.md) - the lazy.nvim#2153 row.
