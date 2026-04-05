# dotfiles

Personal workstation configuration managed with [chezmoi](https://www.chezmoi.io/).

## One-line install

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/stpntkhnv/dotfiles/main/install.sh)"
```

Installs chezmoi (if missing), clones this repo, asks a few setup questions, then installs packages and applies all configs.

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
