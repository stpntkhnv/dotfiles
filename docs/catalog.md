# Каталог фич

<!-- ФАЙЛ ГЕНЕРИРУЕТСЯ. Правки руками будут стёрты.
     Источник: home/.chezmoidata.yaml и шапки covers в docs/*.md
     Пересобрать: tools/gen-catalog.sh -->

Все 35 фич каталога. Столбец «Документ» ведёт в подробное описание.

| Фича | Что это | Где | Как включается | Пакетов | Документ |
|---|---|---|---|---|---|
| `core` | Base utilities | both | всегда | 21 | — |
| `shell` | Shell: starship, eza, bat, fzf, zoxide, ripgrep, fd | both | всегда | 9 | — |
| `container-base` | Container plumbing | container | всегда | 11 | — |
| `host-base` | Host essentials: network, Bluetooth, firewall, zram | host | всегда | 12 | — |
| `desktop` | Desktop: niri + DankMaterialShell | host | всегда | 32 | — |
| `tailscale` | Tailscale VPN | host | всегда | 1 | — |
| `distrobox` | distrobox + podman | host | всегда | 2 | — |
| `herdr` | herdr: agent-aware multiplexer (primary) | both | галочка стоит | 1 | — |
| `tmux` | tmux (fallback multiplexer) | both | галочка стоит | 1 | — |
| `neovim` | Neovim + LSP, treesitter | both | галочка стоит | 2 | — |
| `node` | Node.js + npm | both | галочка стоит | 2 | — |
| `vscode` | VS Code + extensions from extensions.txt | both | по выбору | 1 | — |
| `browsers` | Firefox + Chromium | host | галочка стоит | 2 | — |
| `zen` | Zen browser + Junction link picker | host | всегда | 2 | — |
| `printing` | Printing (CUPS) | host | галочка стоит | 3 | — |
| `docker` | Docker + lazydocker | host | по выбору | 4 | — |
| `go` | Go | both | по выбору | 1 | — |
| `dotnet` | .NET SDK + ASP.NET, freetds, devtunnel | both | галочка стоит | 8 | — |
| `rider` | JetBrains Rider | both | галочка стоит | 1 | — |
| `db-tools` | DB clients: DBeaver (GUI), lazysql, usql, sqlcmd (TUI) | both | галочка стоит | 4 | — |
| `api-tools` | API clients: Bruno (GUI), posting (TUI) | both | галочка стоит | 2 | — |
| `bitwarden` | Passwords: Bitwarden + rbw (terminal) + bws (agent secrets) | both | галочка стоит | 3 | — |
| `claude` | Claude Code CLI | both | галочка стоит | 1 | — |
| `codex` | OpenAI Codex CLI | both | по выбору | 1 | — |
| `gh` | GitHub CLI | both | галочка стоит | 1 | — |
| `azure` | Azure CLI + azd | both | по выбору | 1 | — |
| `teams` | Teams for Linux | both | по выбору | 1 | — |
| `ziti` | OpenZiti edge tunnel | both | по выбору | 1 | — |
| `killswitch` | Kill-switch: drop egress that bypasses the VPN | container | по выбору | 0 | — |
| `voice` | Voice input (Handy, offline) | host | по выбору | 2 | — |
| `voice-postprocess` | Voice input: local LLM cleanup (punctuation, formatting) | host | по выбору | 1 | — |
| `syncthing` | Syncthing: notes and phone media sync | host | галочка стоит | 2 | — |
| `obsidian` | Obsidian (notes editor) | host | галочка стоит | 1 | — |
| `wallpapers` | Wallpapers into ~/Pictures/wallpapers | host | галочка стоит | 0 | — |
| `bluetooth-fix` | Fix for cheap USB Bluetooth dongle (10d7:b012) | host | по выбору | 0 | — |

Пакеты посчитаны из всех источников фичи: pacman, AUR, npm, dotnet tool.
