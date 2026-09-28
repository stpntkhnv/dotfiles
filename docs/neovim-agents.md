---
covers:
  features: []
  paths:
    - home/dot_config/nvim/lua/agent_send.lua
    - home/dot_config/nvim/lua/plugins/agents.lua
    - home/dot_config/nvim/lua/plugins/codediff.lua
    - home/dot_config/nvim/lua/plugins/markdown.lua
---

# Neovim beside agents

## What it does

The part of the `neovim` config ([neovim.md](neovim.md)) for code that Claude
Code or Codex writes in the neighbouring herdr pane: reload, review, sending
context to the agent, reading its markdown. Runs inside the contexts, where
nvim and the agent share one container and one `$HOME`.

## Files

| Path | Role |
|---|---|
| `home/dot_config/nvim/lua/plugins/codediff.lua` | codediff.nvim and the `<leader>g` review keys |
| `home/dot_config/nvim/lua/plugins/agents.lua` | claudecode.nvim, its `<leader>a` keys, `share_claude_ide_dir` |
| `home/dot_config/nvim/lua/agent_send.lua` | types `path:line` into another herdr pane; keys in `lua/keymaps.lua` |
| `home/dot_config/nvim/lua/plugins/markdown.lua` | render-markdown.nvim, off inside CodeDiff tabs |

## How it works

- Reload: `lua/autocmds.lua` runs `checktime` on focus, buffer enter, cursor
  hold and a 1 s timer in normal mode, so a clean buffer reloads without a
  keypress; unsaved edits get nvim's W12 prompt instead; tmux needs
  `focus-events` for `FocusGained` ([multiplexer.md](multiplexer.md)).
  Roslyn sees unopened files on its own: nvim 0.12 offers no
  `didChangeWatchedFiles` on Linux and roslyn watches the disk itself (a new
  class seen without restart, 2026-09-27).
- Review: codediff.nvim, each key `-C` on the current file's repo:
  `<leader>gd` working tree, `<leader>gr` `base...HEAD`, `<leader>gf` file
  history, `<leader>gF` repo history. The view follows the working tree while
  an agent writes. First use downloads `libvscode_diff` and `codediff-watcher`
  from its GitHub releases.
- Claude: claudecode.nvim runs the IDE WebSocket server with
  `provider = 'none'`; Claude stays in its pane and connects with `/ide`.
  `<leader>ab` / `<leader>as` send file / selection as an @-mention (in the
  tree: the node, via `tree_add` for the dotnet-tree source),
  `<leader>aa` / `<leader>ad` accept / deny a proposed diff (new tab).
- Any agent: `<leader>ap` types `path:N ` or `path:A-B ` into another herdr
  pane via `herdr pane send-text`, no Enter. Target: the only other pane in
  the tab, else a picker over the workspace, kept for the session;
  `<leader>aP` picks again.
- Markdown: render-markdown.nvim, `<leader>tm` per buffer; off inside a
  CodeDiff tab (`CodeDiffOpen` / `CodeDiffClose`), where its virtual lines
  would break the diff alignment.

## Constraints

- `share_claude_ide_dir` links every `~/.claude-*/ide` to `~/.claude/ide` at
  start: claudecode writes its lock file to one config dir and Claude reads
  only its own, so `claude-super` and `claude-g` (claudefiles wrappers setting
  `CLAUDE_CONFIG_DIR`) never saw nvim. A real `ide` dir is left alone.
- `agents.lua` `config` wraps claudecode's internal
  `_format_path_for_at_mention` to send absolute paths: it made them relative
  to nvim's cwd, so nvim in the umbrella folder sent `@repo/file` to a Claude
  already inside `repo`. Claude shortens the absolute path itself. Recheck
  after a plugin update.
- `agent_send.lua` falls back to the host's static `/run/host/usr/bin/herdr`
  and needs the `HERDR_*` vars, `HERDR_SOCKET_PATH` included, which
  `distrobox enter` passes through; `distrobox-host-exec` exits 127 here. The
  target is not taken from `herdr agent list`: every context pane is labelled
  `claude` ([multiplexer.md](multiplexer.md)).
- CodeDiff view keys (`codediff.lua` `opts`): explorer `<leader>E`, compact
  `gC`; the defaults `<leader>b` and `gc` stalled `<leader>b*` and hid comments.
- `markdown.lua` clears the `render-markdown.nvim` namespace after
  `buf_disable`: the plugin redraws via the buffer's window in another tab, so
  its marks stayed (2026-09-27).

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| codediff.nvim, 2026-09-27 | made for reviewing agent edits live: hunk stage/discard, `-C`, history | diffview-plus.nvim (drop-in fork, used one day); `sindrets/diffview.nvim` (no push since 2024-08-02) |
| herdr `send-text` keymap | reaches Claude and Codex, no plugin | sidekick.nvim (tmux/zellij only); claudecode `ClaudeCodeSendText` (in-editor terminal only) |
| claudecode `provider = 'none'` | Claude keeps its herdr pane and its account wrapper | in-editor terminal |

## Verify

```sh
ls -l ~/.claude-super/ide   # -> ~/.claude/ide
# with nvim open, in claude-super: /ide lists Neovim; <leader>ab puts
# @<file> into Claude's prompt
# headless tests: :Lazy load claudecode.nvim (VeryLazy never fires) and
# vim.wait, not :sleep, which blocks the WebSocket server
```

## See also

- [neovim.md](neovim.md) - the rest of the config.
- [agents.md](agents.md) - what the repo lays down for Claude Code and Codex.
- [workarounds.md](workarounds.md) - the claudecode.nvim and distrobox rows.
