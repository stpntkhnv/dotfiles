---
covers:
  features: []
  paths:
    - home/dot_config/nvim/lua/plugins/csharp.lua
    - home/dot_config/nvim/lua/plugins/tests.lua
    - home/dot_config/nvim/lua/plugins/debug.lua
    - home/dot_config/nvim/lua/plugins/file-explorer.lua
    - home/dot_config/nvim/private_snippets/**
---

# Neovim for C#

## What it does

The C#/.NET part of the `neovim` config ([neovim.md](neovim.md)): Roslyn, the
solution explorer, tests, debugging, JSON configs and csharpier. Runs in the
contexts (`scope: both`, not enabled on the host), tuned for many
ASP.NET/Aspire repos under one folder inside an 8g container.

## Files

| Path | Role |
|---|---|
| `home/dot_config/nvim/lua/plugins/csharp.lua` | roslyn.nvim, its settings and the `peekReferences` handler |
| `home/dot_config/nvim/lua/plugins/tests.lua` | neotest + neotest-vstest, `<leader>T` keys |
| `home/dot_config/nvim/lua/plugins/debug.lua` | nvim-dap, dap-ui, netcoredbg adapters |
| `home/dot_config/nvim/lua/plugins/file-explorer.lua` | neo-tree with the dotnet-tree source, `open_explorer` |
| `home/dot_config/nvim/private_snippets/**` | `cs.json` + `package.json`, deployed as `snippets/`; LuaSnip's vscode loader reads a directory only through `package.json` |

JSON schemas and csharpier live in `lua/plugins/lsp.lua`; the roslyn registry
in `mason.lua` ([neovim.md](neovim.md)).

## How it works

- Roslyn settings (`csharp.lua` `init`): inlay hints, completion from
  unimported namespaces (they arrive on the second request, once the index is
  built; accepting one adds the `using`), organize imports on format,
  references code lens (`grx` lists them via fzf-lua; roslyn only, yamlls would
  title every YAML), `gd` into decompiled sources. Diagnostics stay on open
  files: Roslyn's default `openFiles`, not set here.
- JSON (`lsp.lua`): jsonls with SchemaStore.nvim validates and completes
  `appsettings*.json`, `launchSettings.json`, `global.json`. Its formatter is
  off (`provideFormatter = false`): format on save would rewrite every JSON.
- csharpier (`lsp.lua` `csharpier_root`): on save only in a git repo whose root
  `dotnet-tools.json` lists it (`dotnet csharpier`, cwd = root) or that holds a
  `.csharpierrc*` (mason's `csharpier`); elsewhere Roslyn formats. No work repo
  has it (2026-09-28).
- Explorer (`file-explorer.lua`): `\` opens dotnet-tree, the solution view
  (solution folders, projects, references, packages), when the current file's
  repo root holds a `.sln`/`.slnx`, else Files. Winbar `.NET | Files`, `<` /
  `>` switch; bare `:Neotree` stays on Files (`default_source`). In the
  solution view: `b`/`B` build to quickfix, `r` run, `t` test, `d` debug via
  netcoredbg with the `launchSettings.json` profile, `s` pick a solution,
  `?` help.
- Tests: neotest-vstest speaks Microsoft Testing Platform (xUnit v3, 10/10 on
  2026-09-27); `broad_recursive_discovery` is off, a folder of many repos
  would freeze nvim.

## Constraints

- roslyn settings live in the spec's `init`, not `config`: roslyn.nvim's
  `plugin/roslyn.lua` calls `vim.lsp.enable("roslyn")` when the plugin loads,
  before `config` runs, so the client started without them (inlay hints 0
  before the move, 2 after, 2026-09-27).
- `ROSLYN_LANGUAGE_SERVER_DAEMON_KEEPALIVE=0`, same `init`: roslyn.nvim newer
  than the pinned `c4ef259` runs the server as a daemon alive 900 s after the
  last client - a solution-sized process left under the 8g cap.
- `csharp.lua` registers `roslyn.client.peekReferences` in `vim.lsp.commands`
  and jumps with `show_document(..., 'utf-16')`: roslyn.nvim handles only
  three client commands, so `grx` on a references lens failed
  ([workarounds.md](workarounds.md)).
- csharpier's repo is found per file: conform's built-in `is_local()` asks
  `dotnet csharpier --version` once per session from nvim's cwd, the umbrella
  folder. `.cs` saves get 3 s, not 0.5 s: `dotnet csharpier` starts in ~0.4 s.
- `launchSettings.json` needs `replace` in the SchemaStore call, under `pcall`
  so a catalog without the entry cannot abort the LSP config: the catalog's
  `fileMatch` is lowercase, jsonls matches case-sensitively
  ([workarounds.md](workarounds.md)).
- `open_explorer` disposes the tab's dotnet-tree state when the repo changes
  and seeds the new one's `path`: its `navigate` ignores neo-tree's `dir=` and
  caches the first solution, so nvim in the umbrella folder showed "no
  .sln/.slnx found". Changing `path` on a rendered state made neo-tree
  close its new window (`Invalid window`). `<` / `>` show the repo of the last
  `\` ([workarounds.md](workarounds.md)).

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| neotest-vstest, 2026-09-27 | neotest-dotnet discovery crashes on nvim 0.12 (`get_node_text`, `attempt to call method 'start'`), unmaintained since 2025-09 | easy-dotnet test runner (starts its own Roslyn) |
| dotnet-tree.nvim, 2026-09-27 | a neo-tree source, so Files stays one key away; solution parsed in Lua, no MSBuild. Early, one author | easy-dotnet (own Roslyn); explorer.dotnet.nvim, dotnet-workspace-explorer.nvim (standalone trees) |
| Diagnostics on open files only, 2026-09-28 | solution-wide analysis costs RAM and CPU beside Aspire and builds | `fullSolution` (Rider-style, feeds dotnet-tree's error counts) |

## Verify

```sh
# in a context, inside a solution, a .cs buffer:
#   :lua print(vim.bo.indentexpr)       -> GetCSIndent(v:lnum)
#   :lua =vim.tbl_keys(vim.lsp.get_clients({name='roslyn'})[1].settings)
#                                        -> includes csharp|inlay_hints, navigation
#   :lua =vim.tbl_map(function(s) return s.trigger end, require('luasnip').get_snippets('cs'))
#                                        -> includes recordp
```

## See also

- [neovim.md](neovim.md) - the rest of the config.
- [workarounds.md](workarounds.md) - dotnet-tree, roslyn.nvim, SchemaStore rows.
