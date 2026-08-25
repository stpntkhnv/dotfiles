---
covers:
  features: [neovim, vscode, node, go, dotnet, rider, db-tools, api-tools, docker, azure, teams, gh]
  paths:
    - home/dot_config/nvim/**
    - home/dot_config/Code/User/extensions.txt
    - home/dot_config/Code/User/keybindings.json
    - home/dot_config/Code/User/settings.json
    - home/dot_config/code-flags.conf
    - home/dot_npmrc
    - home/.chezmoiscripts/run_onchange_after_81-vscode-extensions.sh.tmpl
    - home/.chezmoiscripts/run_onchange_before_70-azure.sh.tmpl
---

# Dev tools

## What it does

Twelve one-tool features: `neovim vscode node go dotnet rider db-tools
api-tools docker azure teams gh`. All `scope: both`; off by default: `vscode
docker go azure teams`. Packages and `dotnet`'s global tools live in their
`home/.chezmoidata.yaml` blocks, installed by
`run_onchange_before_20-packages.sh.tmpl` ([how-it-works.md](how-it-works.md));
only `vscode` and `azure` add a script. `rider` `needs: [dotnet]`;
`db-tools`/`api-tools` are clients, servers run in containers; `node` ships no
npm package itself (20's npm block serves `claude`/`codex`).

## Files

| Path | Role |
|---|---|
| `home/dot_config/nvim/**` | 29 files; plugin specs one per file in `lua/plugins/`. `mason.lua` adds `Crashdummyy/mason-registry` for Roslyn (C# LSP), not in the official one. `lazy-lock.json` moves only on `:Lazy update` |
| `.../Code/User/extensions.txt` | 47 ids, read by 81 |
| `.../Code/User/settings.json` | `dotnet.defaultSolution`, `@azure.argTenant` empty on purpose |
| `.../Code/User/keybindings.json` | `shift+enter` = `\` + CRLF in terminal |
| `home/dot_config/code-flags.conf` | Wayland Electron flags; path is a VS Code packaging convention |
| `home/dot_npmrc` | `prefix=~/.npm-global` (literal tilde), `allow-scripts=@anthropic-ai/claude-code` |
| `...81-vscode-extensions.sh.tmpl` | installs missing extensions |
| `...70-azure.sh.tmpl` | installs `azd` if absent |

`.chezmoiignore` drops each tree whole when its feature is off.

## How it works

- 81 `include`s `extensions.txt` into its own rendered text from the chezmoi
  **source** tree, not `~`; `run_onchange_` hashes that text, so editing the list
  re-triggers the script and editing the deployed copy does nothing. Each install
  ends in `|| echo "!! failed..."`, so one failure does not abort the rest.
- 20 uses `dotnet tool update -g`, not `install`: `update` installs a missing
  tool too since .NET 8, so the call is idempotent.

## Constraints

- `--allow-scripts=@anthropic-ai/claude-code` is on 20's `npm install -g` line,
  not just `~/.npmrc`: 20 is a `before` script, so that file does not exist
  yet on a clean machine and the postinstall linking the `claude` binary is
  blocked, leaving a dangling symlink ([base.md](base.md)).
- 20 runs `npm config set prefix` only when it already differs: it rewrites
  all of `~/.npmrc`, losing comments and the tilde
  ([workarounds.md](workarounds.md), npm/npm#7771).
- `docker` gives the host `docker.socket` + group
  (`run_onchange_before_30-system.sh.tmpl`, host-only; group needs a re-login,
  `zz-next-steps` nags). A container gets neither by design - its CLI
  points at nested podman via `DOCKER_HOST`
  ([nested-podman.md](nested-podman.md)) or at the host socket
  ([containers.md](containers.md)).
- The `SSL_CERT_DIR` block in `home/dot_bashrc.tmpl` is inert until
  `dotnet dev-certs https --trust` exports into `~/.aspnet/dev-certs/trust`, and
  needs a **new** shell after - otherwise the Aspire dashboard rejects its own
  resource service with `UntrustedRoot`.
- `DOTNET_gcServer=0`, `DOTNET_GCConserveMemory=5` and
  `MSBUILDDISABLENODEREUSE=1` are set for container work by
  `home/dot_bashrc.tmpl`. A .NET process sizes its heap against the cgroup limit
  as if nothing else were in there, and Server GC opens one heap per core, so
  six Aspire services plus a build did not fit under `--memory=8g`
  ([issues/2026-08-24-container-livelock-at-memory-cap.md](issues/2026-08-24-container-livelock-at-memory-cap.md)).
- They ride on the `<ctx>` entry aliases, host-side, like `HERDR_AGENT`
  ([multiplexer.md](multiplexer.md)). That placement is load-bearing:
  `distrobox enter <ctx> -- <cmd>` runs the command with no shell, so the
  container's `.bashrc` is never read - on that path even `PATH` is the host's.
  Builds here are started by agents through the `-claude` and `-tmux` aliases,
  not typed into a shell, so an in-container export alone would have missed
  every one of them. The block inside the container's rc is the fallback for a
  shell entered some other way, and `.bashrc` line 1 returns early when
  non-interactive.
- These cap cost per process, not process count: a build still forks one MSBuild
  node per core unless it is given `-m:4`.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| Extension list in its own `.txt` | List edits stay distinct from logic edits, still re-trigger `run_onchange_` | Inline in script |
| `azd` from the `aka.ms` script | Not in Arch repos or AUR; the only Linux path Microsoft documents | pacman/AUR |
| `docker` scope `both`, 2026-08-02 | Container needs the client, not a daemon | Host-only |
| `devtunnel-cli-bin` dropped, 2026-08-01 | AUR build kept failing; Tailscale covers tunnels | Keep it |
| Workstation GC in containers, 2026-08-24 | One heap per process instead of one per core; a dev run never notices the throughput, the 8g lid does | Raising `--memory` (moves the cliff, revives the 2026-07-30 desktop risk); `DOTNET_GCHeapHardLimitPercent` (a hard limit turns overshoot into `OutOfMemoryException` mid-build) |

## Verify

```sh
git ls-files -- 'home/dot_config/nvim/**' | wc -l  # 29
npm config get prefix                              # else 20 rewrites ~/.npmrc

# In a container, in a NEW shell: 0, and a running .NET service must show no
# ".NET Server GC" threads at all (it showed 12, one per core, before 2026-08-24)
echo "$DOTNET_gcServer"
cat /proc/<pid>/task/*/comm | sort | uniq -c
```
