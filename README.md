# dotfiles

Personal workstation configuration managed with [chezmoi](https://www.chezmoi.io/).

## One-line install

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/stpntkhnv/dotfiles/main/install.sh)"
```

If the script was recently updated and you're getting stale content from CDN cache, use the GitHub API instead:

```sh
sh -c "$(curl -fsSL https://api.github.com/repos/stpntkhnv/dotfiles/contents/install.sh -H 'Accept: application/vnd.github.raw')"
```

Installs chezmoi (if missing), clones this repo, asks a few setup questions, then installs packages and applies all configs.

## Distrobox containers

Always pass `--name <containername>` — distrobox-assemble treats every `[section]` in the INI as a container, including `[base]`, so omitting `--name` will also create a redundant `base` container.

```sh
distrobox assemble create --name digi3 --file https://raw.githubusercontent.com/stpntkhnv/dotfiles/main/home/dot_config/distrobox/distrobox.ini
```

The `archlinux:latest` base image is bare — it ships with an empty `mirrorlist` and no `Include` for `[extra]`. The chezmoi-driven setup script populates both before the first `pacman -Syu`, so no manual bootstrap is needed.

### Setting up a new container

After creating a container, enter it and run the chezmoi installer:

```sh
distrobox enter <name>
sh -c "$(curl -fsSL https://raw.githubusercontent.com/stpntkhnv/dotfiles/main/install.sh)"
```

After that, exit and use the tmux alias (e.g. `personal`, `digi3`, `stellium`).

### util-linux 2.42 workaround (auto-applied)

util-linux 2.42 has a regression in `su --pty` that breaks `distrobox enter` for containers with `init=true` (see [distrobox#2052](https://github.com/89luca89/distrobox/issues/2052) and [util-linux PR#4185](https://github.com/util-linux/util-linux/pull/4185), merged but not yet released).

The manifest's `init_hooks` automatically downgrades util-linux to `2.41.3-2` and pins it via `IgnorePkg` on first container init by fetching `home/bin/util-linux-fix.sh` from this repo. No manual steps required.

Once util-linux 2.42.1+ lands in the Arch repos, remove the `init_hooks` line in the manifest and the `IgnorePkg` lines from `/etc/pacman.conf` in each existing container.

## What gets configured

- niri + DankMaterialShell (host only)
- bash + starship
- Neovim
- tmux
- Git
- VS Code + extensions
- Firefox + Auto Tab Discard
- Claude Code MCP servers

### Optional features (prompted during init)

| Flag | What it does |
|------|-------------|
| `setup_voice` | Offline speech-to-text (see below) |
| `setup_azure` | Azure CLI, azd, Azure MCP server |
| `setup_teams` | Teams for Linux with memory limit |
| `setup_ziti` | OpenZiti edge tunnel + systemd service |

## Voice input

`setup_voice` installs [Handy](https://handy.computer), an offline
speech-to-text app, plus a `voice_backend` choice (only `handy` for now).

Handy runs Whisper through whisper.cpp, whose Linux GPU backend is **Vulkan,
not CUDA** — a GPU only needs its normal driver and Vulkan ICD, and the CUDA
toolkit does nothing for it. `chezmoi init` probes for an NVIDIA card by
reading `/sys/bus/pci` (not `lspci`, which a minimal install may lack); if one
is present without a working Vulkan runtime it offers to install
`nvidia-open`/`nvidia-utils`. That install needs a reboot, which is why the
question is asked at init rather than mid-apply. Non-Whisper models (Parakeet,
GigaAM, …) are CPU-only regardless of the GPU.

Tauri's global-shortcut plugin cannot grab keys on wlroots-style compositors,
so niri owns the keybind and signals the running process instead —
`Mod+Shift+D` sends `SIGUSR2`. That binding and `spawn-at-startup` live in
`home/dot_config/niri/voice.kdl.tmpl`, which `config.kdl` includes
unconditionally and which renders to a comment-only file when voice input is
off.

After installing, launch Handy once and download a model (Settings → Model).
Whisper Large v3 Turbo (~1.6 GB) is the multilingual GPU-accelerated one.
