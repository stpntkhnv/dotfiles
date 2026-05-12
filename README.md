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

- zsh + Oh My Zsh + Powerlevel10k
- Neovim
- tmux
- Git
- VS Code + extensions
- Firefox + Auto Tab Discard
- Claude Code MCP servers

### Optional features (prompted during init)

| Flag | What it does |
|------|-------------|
| `setup_azure` | Azure CLI, azd, Azure MCP server |
| `setup_ado` | Azure DevOps MCP server (PAT auth) |
| `setup_teams` | Teams for Linux with memory limit |
| `setup_ziti` | OpenZiti edge tunnel + systemd service |
| `setup_docker_forward` | socat port forwarding for isolated distrobox |
