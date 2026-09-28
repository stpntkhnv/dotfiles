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
feature is off. The config is tuned for C#/.NET through Roslyn; the part for
code agents write is [neovim-agents.md](neovim-agents.md).

## Files

| Path | Role |
|---|---|
| `home/dot_config/nvim/**` | 32 files. `init.lua` loads `lua/{options,keymaps,autocmds,plugins}.lua`; one lazy.nvim spec per file in `lua/plugins/`. `lazy-lock.json` pins every plugin and moves when lazy installs, cleans or updates one |
| `.../lua/plugins/mason.lua` | adds `Crashdummyy/mason-registry`: its `roslyn` meets roslyn.nvim's minimum server version, mason-org's `roslyn-language-server` did not (2026-09-27) |
| `.../lua/plugins/file-explorer.lua` | neo-tree with the dotnet-tree source and `open_explorer` |
| `.../private_snippets/{cs.json,package.json}` | deployed as `snippets/`; LuaSnip's vscode loader reads a directory only through its `package.json` |

## How it works

- C#: roslyn.nvim (`lua/plugins/csharp.lua`), blink.cmp + LuaSnip, conform
  (format on save falls back to Roslyn), nvim-dap + netcoredbg
  (`debug.lua`), neotest-vstest (`tests.lua`).
- Roslyn settings (`csharp.lua` `init`): inlay hints, completion from
  unimported namespaces (they arrive on the second request, once the index is
  built; accepting one adds the `using`), organize imports on format,
  references code lens (`grx` opens them in Telescope; enabled for roslyn
  only, yamlls would title every YAML), `gd` into decompiled sources.
  Diagnostics stay on open files: Roslyn's default `openFiles`, not set here.
- JSON (`lsp.lua`): jsonls with SchemaStore.nvim, so `appsettings*.json`,
  `launchSettings.json` and `global.json` validate and complete. Its
  formatter is off (`provideFormatter = false`): format on save would rewrite
  every JSON the repos hold.
- csharpier (`lsp.lua` `csharpier_root`): runs on save only in a git repo
  whose root `dotnet-tools.json` lists it (`dotnet csharpier`, cwd = root) or
  that holds a `.csharpierrc*` (mason's `csharpier`); elsewhere Roslyn formats. No
  work repo has it (2026-09-28).
- LSP maps (`lsp.lua`, `LspAttach`): Telescope pickers sit on nvim's own
  `grr` `gri` `grt`; `gd` and `gD` stay.
- Treesitter runs the `main` branch (`treesitter.lua`): the listed parsers
  install at startup (`ts.install {`), any other on its first `FileType`, and
  highlighting starts per buffer.
- Explorer (`file-explorer.lua`): `\` opens dotnet-tree, the solution view
  (solution folders, projects, references, packages), when the current file's
  repo root holds a `.sln`/`.slnx`, else the filesystem source. The winbar
  `.NET | Files` switches with `<` / `>`; bare `:Neotree` stays on Files
  (`default_source`). In the solution view: `b`/`B` build
  to quickfix, `r` run, `t` test, `d` debug via netcoredbg with the
  `launchSettings.json` profile, `s` pick a solution, `?` help.

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
  query (`treesitter.lua`, `start()`): `c_sharp` has none, and that indentexpr put the line after
  `{` at column 0. C# keeps the runtime `GetCSIndent`.
- No `gr`, `gi`, `gt` maps (`lsp.lua`, `LspAttach`): a buffer-local `gr` waited `timeoutlen` for nvim's
  default `grn`/`grr`/..., and `gi`/`gt` shadowed builtins.
- yamlls (`lsp.lua`, `vim.lsp.config('yamlls'`) has no catch-all
  `kubernetes = '*.yaml'`: the work repos hold no manifests, and it put false
  errors on `compose.yaml` (2) and an Azure pipeline (6), 2026-09-27. yamlls
  pulls SchemaStore by itself.
- No mason-lspconfig: v2 auto-enabled every mason server and started
  `stylua --lsp` as a second Lua client beside conform. `lsp.lua` enables
  `lua_ls`, `yamlls` and `jsonls`, roslyn.nvim enables `roslyn`.
- `open_explorer` disposes the tab's dotnet-tree state when the repo changes
  and seeds the new one's `path` with the repo root: the source's `navigate`
  ignores neo-tree's `dir=` and caches the first solution, so nvim in the
  umbrella folder showed "no .sln/.slnx found". Changing `path` on a state
  that had already rendered made neo-tree close its new window (`Invalid
  window`). `<` / `>` show the repo of the last `\`
  ([workarounds.md](workarounds.md)).
- `csharp.lua` registers `roslyn.client.peekReferences` in `vim.lsp.commands`:
  roslyn.nvim handles only three client commands, so `grx` on a references
  lens failed ([workarounds.md](workarounds.md)).
- csharpier's repo is found per file, not taken from conform: its built-in
  `is_local()` asks `dotnet csharpier --version` once per session from nvim's
  cwd, which is the umbrella folder. `.cs` saves get 3 s instead of 0.5 s:
  `dotnet csharpier` starts in ~0.4 s.
- `launchSettings.json` needs `replace` in the SchemaStore call, under
  `pcall` so a catalog without that entry cannot abort the LSP config: the catalog's
  `fileMatch` is lowercase and jsonls matches case-sensitively on Linux
  ([workarounds.md](workarounds.md)).
- Tests: neotest-vstest speaks Microsoft Testing Platform (xUnit v3, 10/10 on
  2026-09-27). `broad_recursive_discovery` is off: a folder of many repos would
  freeze nvim.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| neotest-vstest, 2026-09-27 | neotest-dotnet discovery crashes on nvim 0.12 (`get_node_text`, `attempt to call method 'start'`), unmaintained since 2025-09 | easy-dotnet test runner (starts its own Roslyn) |
| dotnet-tree.nvim, 2026-09-27 | a neo-tree source, so Files stays one key away; solution parsed in Lua, no MSBuild, nothing extra under the 8g cap. Early, one author | easy-dotnet (starts its own Roslyn); explorer.dotnet.nvim, dotnet-workspace-explorer.nvim (standalone trees) |
| Roslyn diagnostics on open files only, 2026-09-28 | solution-wide analysis costs RAM and CPU under the 8g cap, beside Aspire and builds | `fullSolution` (Rider-style, feeds dotnet-tree's error counts) |
| kulala.nvim dropped, 2026-09-27 | upstream repo went private (404) | 1-star recovery fork |

## Verify

```sh
git ls-files -- 'home/dot_config/nvim/**' | wc -l   # 32
# in a context, inside a solution, a .cs buffer:
#   :lua print(vim.bo.indentexpr)                      -> GetCSIndent(v:lnum)
#   :lua =vim.lsp.get_clients({name='roslyn'})[1].settings  -> has csharp|inlay_hints
#   :lua =vim.tbl_map(function(s) return s.trigger end, require('luasnip').get_snippets('cs'))  -> includes recordp
```

## See also

- [dev-tools.md](dev-tools.md) - the other editors and SDKs.
- [neovim-agents.md](neovim-agents.md) - reload, review and sending context
  to agents.
- [workarounds.md](workarounds.md) - the lazy.nvim, dotnet-tree, roslyn.nvim
  and SchemaStore rows.
