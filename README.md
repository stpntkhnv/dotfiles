# dotfiles

Personal workstation configuration managed with [chezmoi](https://www.chezmoi.io/).

## One-line install

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/stpntkhnv/dotfiles/main/install.sh)"
```

Installs chezmoi (if missing), clones this repo, asks a few setup questions, then installs packages and applies all configs.

## Distrobox containers

Create all containers from the manifest without cloning the repo:

```sh
distrobox assemble create --file https://raw.githubusercontent.com/stpntkhnv/dotfiles/main/home/dot_config/distrobox/distrobox.ini
```

Or a single container by name:

```sh
distrobox assemble create --name digi3 --file https://raw.githubusercontent.com/stpntkhnv/dotfiles/main/home/dot_config/distrobox/distrobox.ini
```

### Setting up a new container

After creating a container, enter it and run the chezmoi installer:

```sh
distrobox enter <name>
sh -c "$(curl -fsSL https://raw.githubusercontent.com/stpntkhnv/dotfiles/main/install.sh)"
```

After that, exit and use the tmux alias (e.g. `personal`, `digi3`, `stellium`).

### Known issue: util-linux 2.42 breaks init containers

`su --pty` in util-linux 2.42 (shipped in Arch on 2026-04-03) passes `--pty` to the shell instead of handling it, which breaks `distrobox enter` for containers created with `--init`.

**Upstream links:**
- [distrobox#2052](https://github.com/89luca89/distrobox/issues/2052)
- [util-linux PR#4185](https://github.com/util-linux/util-linux/pull/4185) (fix, not yet merged)

**Root cause:** commit `ac0147fd` added `+` prefix to `getopt` optstring in `su-common.c`, which makes `su` stop parsing options at the first non-option argument (the username). Options like `--pty` after the username get forwarded to the shell. The fix separates behavior for `su` and `runuser`.

**Workaround:** downgrade util-linux inside the container and pin it:

```sh
podman exec -u root <name> bash -c "curl -LO https://archive.archlinux.org/packages/u/util-linux/util-linux-2.41.3-2-x86_64.pkg.tar.zst && curl -LO https://archive.archlinux.org/packages/u/util-linux-libs/util-linux-libs-2.41.3-2-x86_64.pkg.tar.zst && pacman -Udd --noconfirm util-linux-2.41.3-2-x86_64.pkg.tar.zst util-linux-libs-2.41.3-2-x86_64.pkg.tar.zst"
```

Then pin to prevent re-upgrade — add inside `[options]` in the container's `/etc/pacman.conf`:

```
IgnorePkg = util-linux util-linux-libs
```

Remove the pin once util-linux ships a fixed version (2.42.1+).

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
