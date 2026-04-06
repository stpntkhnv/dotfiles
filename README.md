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
