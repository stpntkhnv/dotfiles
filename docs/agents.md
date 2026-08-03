---
covers:
  features: [claude, codex]
  paths:
    - home/.chezmoiexternal.toml.tmpl
    - home/dot_config/systemd/user/user.slice.d/50-agents-budget.conf
---

# Agents: Claude Code and Codex

## What it does

Installs the `claude` and `codex` CLIs, pulls the `claudefiles` repo that
configures Claude, caps agent and container memory. Features `claude`
(`default: true`) and `codex`, `scope: both`, `needs: [node]`.

## Files

| Path | Role |
|---|---|
| `home/.chezmoiexternal.toml.tmpl` | pulls `claudefiles`, behind `has "claude" .enabled` |
| `home/dot_config/systemd/user/user.slice.d/50-agents-budget.conf` | `MemoryHigh=12G`, `MemoryMax=16G`; host only (`.chezmoiignore`) |
| `~/.local/share/claudefiles`, `~/.claude`, `~/.codex` (runtime) | clone, config, logins - one set per home |

## How it works

- npm packages go to `~/.npm-global` via
  `run_onchange_before_20-packages.sh.tmpl` (`---- npm ----`), PATH from
  `home/dot_bashrc.tmpl`. `--allow-scripts=@anthropic-ai/claude-code` is on the
  command line, not only in `home/dot_npmrc`: a fresh container has no
  `~/.npmrc` yet and a blocked postinstall leaves `bin/claude` dangling.
- `claudefiles`: `git-repo` external, `refreshPeriod = "168h"`,
  `pull.args = ["--ff-only"]` - nothing commits locally, so divergence means an
  upstream force-push and should fail loud.
- `chezmoi apply` never runs `setup.sh`; `run_after_zz-next-steps.sh.tmpl`
  nags until clone `HEAD` equals `~/.config/claudefiles/last-applied-head`,
  which `setup.sh` writes on success. What it puts in `~/.claude` (MCP,
  plugins, skills) is outside this repo.
- Per context: home is `~/homes/<ctx>`, so a host login does not carry in; the
  `.bashrc` wrappers are host-only, and in a container `claude` is the plain
  binary in the container's cgroup, under `--memory=8g`
  ([containers.md](containers.md)).
- Budget: rootless podman parents every `libpod-*` scope under the user
  manager's `user.slice` (checked 2026-08-02: nothing else is there), so one
  drop-in covers containers and agents; host sessions join through the
  `.bashrc` wrapper `slice-run user-agents.slice claude`.
  `run_onchange_after_33-browser-slices.sh.tmpl` hashes it, reloads systemd.

## Constraints

- Shared budget, no per-session knob: one agent may take all 12G.
- No channel to secrets exists ([secrets.md](secrets.md)).

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| Budget on `user.slice` | podman parents containers there already | own `agents.slice`: no global `cgroup_parent` in `containers.conf`, and per-container `--cgroup-parent` misses distrobox ones |
| `setup.sh` by hand | interactive installer held `apply` hostage | auto-run, deleted 2026-08-01 (`af8abfb`) |
| Nag on `HEAD` != marker | fires only when the clone moved | nagging every apply |

## Verify

```sh
type claude   # host: a function; container: ~/.npm-global/bin/claude
git -C ~/.local/share/claudefiles rev-parse HEAD
cat ~/.config/claudefiles/last-applied-head   # equal => setup.sh current
systemctl --user show user.slice -p MemoryHigh -p MemoryMax
              # 12884901888 / 17179869184
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| New `claudefiles` commits, no nag | 168h window open | `chezmoi apply --refresh-externals` |
| Agent child killed | hit `MemoryMax=16G` | expected; `dmesg \| grep -i oom` |

## See also

[dev-tools.md](dev-tools.md), [browsers.md](browsers.md),
[hardware.md](hardware.md), [nested-podman.md](nested-podman.md),
[issues/2026-07-30-desktop-hang-out-of-memory.md](issues/2026-07-30-desktop-hang-out-of-memory.md)
