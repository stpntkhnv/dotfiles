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
| `home/dot_config/nvim/**` | 32 files. `init.lua` loads `lua/{options,keymaps,autocmds,plugins}.lua`; one lazy.nvim spec per file in `lua/plugins/`. `lazy-lock.json` pins every plugin and moves when lazy installs, cleans or updates one |
| `.../lua/plugins/mason.lua` | adds `Crashdummyy/mason-registry`: its `roslyn` meets roslyn.nvim's minimum server version, mason-org's `roslyn-language-server` did not (2026-09-27) |
| `.../lua/plugins/agents.lua` | claudecode.nvim and its `<leader>a` keys |
| `.../lua/agent_send.lua` | types `path:line` into another herdr pane; keys in `lua/keymaps.lua` |
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
- Review: codediff.nvim (`codediff.lua`), each key `-C` on the current file's
  repo: `<leader>gd` working tree, `<leader>gr` `base...HEAD`, `<leader>gf`
  file history, `<leader>gF` repo history. The view follows the working tree
  while an agent writes. First use downloads `libvscode_diff` and
  `codediff-watcher` from its GitHub releases.
- Claude: claudecode.nvim (`agents.lua`) runs the IDE WebSocket server with
  `provider = 'none'`; Claude stays in its own pane and connects with `/ide`.
  `<leader>ab` / `<leader>as` send the file / selection as an @-mention,
  `<leader>aa` / `<leader>ad` accept / deny a proposed diff (new tab).
- Any agent: `<leader>ap` types `path:N ` or `path:A-B ` into another herdr
  pane via `herdr pane send-text`, no Enter. Target: the only other pane in
  the tab, else a picker over the workspace, kept for the session;
  `<leader>aP` picks again.
- Markdown: render-markdown.nvim (`markdown.lua`), `<leader>tm` per buffer.
  Off inside a CodeDiff tab (`CodeDiffOpen` / `CodeDiffClose`), where its
  virtual lines would break the diff alignment.

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
- `share_claude_ide_dir` (`agents.lua`) links every `~/.claude-*/ide` to
  `~/.claude/ide` at start: claudecode writes its lock file to one config dir
  and Claude reads only its own, so `claude-super` and `claude-g` (claudefiles
  wrappers that set `CLAUDE_CONFIG_DIR`) never saw nvim. An existing real
  `ide` dir is left alone ([workarounds.md](workarounds.md)).
- `agents.lua` `config` wraps claudecode's internal
  `_format_path_for_at_mention` to send absolute paths: it made them relative
  to nvim's cwd, so nvim in the umbrella folder sent `@repo/file` to a Claude
  already inside `repo`. Claude shortens the absolute path itself. Recheck
  after a plugin update ([workarounds.md](workarounds.md)).
- `agent_send.lua` falls back to the host's static `/run/host/usr/bin/herdr`
  and needs the `HERDR_*` vars, which `distrobox enter` passes through
  (`HERDR_SOCKET_PATH` included). `distrobox-host-exec` exits 127 here
  ([workarounds.md](workarounds.md)). The target is not taken from
  `herdr agent list`: every context pane is labelled `claude`
  ([multiplexer.md](multiplexer.md)).
- CodeDiff view keys (`codediff.lua` `opts`): explorer `<leader>E`, compact
  `gC`; the defaults `<leader>b` and `gc` stalled `<leader>b*` and hid comments.
- `markdown.lua` clears the `render-markdown.nvim` namespace after
  `buf_disable`: the plugin redraws via the buffer's window in another tab, so
  its marks stayed (2026-09-27).
- Tests: neotest-vstest speaks Microsoft Testing Platform (xUnit v3, 10/10 on
  2026-09-27). `broad_recursive_discovery` is off: a folder of many repos would
  freeze nvim.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| neotest-vstest, 2026-09-27 | neotest-dotnet discovery crashes on nvim 0.12 (`get_node_text`, `attempt to call method 'start'`), unmaintained since 2025-09 | easy-dotnet test runner (starts its own Roslyn) |
| codediff.nvim, 2026-09-27 | made for reviewing agent edits live: hunk stage/discard, `-C`, history | diffview-plus.nvim (drop-in fork, used one day); `sindrets/diffview.nvim` (no push since 2024-08-02) |
| herdr `send-text` keymap | reaches Claude and Codex, no plugin | sidekick.nvim (tmux/zellij only); claudecode `ClaudeCodeSendText` (in-editor terminal only) |
| claudecode `provider = 'none'` | Claude keeps its herdr pane and its account wrapper | in-editor terminal |
| kulala.nvim dropped, 2026-09-27 | upstream repo went private (404) | 1-star recovery fork |

## Verify

```sh
git ls-files -- 'home/dot_config/nvim/**' | wc -l   # 32
# in a context, inside a solution, a .cs buffer:
#   :lua print(vim.bo.indentexpr)                      -> GetCSIndent(v:lnum)
#   :lua =vim.lsp.get_clients({name='roslyn'})[1].settings  -> has csharp|inlay_hints
#   :lua =vim.tbl_map(function(s) return s.trigger end, require('luasnip').get_snippets('cs'))  -> includes recordp
ls -l ~/.claude-super/ide   # -> ~/.claude/ide
# with nvim open, in claude-super: /ide lists Neovim
# headless: :Lazy load claudecode.nvim (no VeryLazy); vim.wait, not :sleep
```

## See also

- [dev-tools.md](dev-tools.md) - the other editors and SDKs.
- [multiplexer.md](multiplexer.md) - tmux `focus-events`, which lets
  `FocusGained` reach nvim.
- [workarounds.md](workarounds.md) - the lazy.nvim, claudecode.nvim and
  distrobox rows.
