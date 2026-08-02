# Каталог фич

<!-- ФАЙЛ ГЕНЕРИРУЕТСЯ. Правки руками будут стёрты.
     Источник: home/.chezmoidata.yaml и шапки covers в docs/*.md
     Пересобрать: tools/gen-catalog.sh -->

Все 36 фич каталога. Столбец «Документ» ведёт в подробное описание.

| Фича | Что это | Где | Как включается | Пакетов | Документ |
|---|---|---|---|---|---|
| `core` | Base utilities | both | всегда | 21 | [base.md](base.md) |
| `shell` | Shell: starship, eza, bat, fzf, zoxide, ripgrep, fd | both | всегда | 9 | [base.md](base.md) |
| `container-base` | Container plumbing | container | всегда | 11 | [containers.md](containers.md) |
| `host-base` | Host essentials: network, Bluetooth, firewall, zram | host | всегда | 12 | [base.md](base.md) |
| `desktop` | Desktop: niri + DankMaterialShell | host | всегда | 32 | [desktop.md](desktop.md) |
| `tailscale` | Tailscale VPN | host | всегда | 1 | [network.md](network.md) |
| `distrobox` | distrobox + podman | host | всегда | 2 | [containers.md](containers.md) |
| `herdr` | herdr: agent-aware multiplexer (primary) | both | галочка стоит | 1 | [multiplexer.md](multiplexer.md) |
| `tmux` | tmux (fallback multiplexer) | both | галочка стоит | 1 | [multiplexer.md](multiplexer.md) |
| `neovim` | Neovim + LSP, treesitter | both | галочка стоит | 2 | [dev-tools.md](dev-tools.md) |
| `node` | Node.js + npm | both | галочка стоит | 2 | [dev-tools.md](dev-tools.md) |
| `vscode` | VS Code + extensions from extensions.txt | both | по выбору | 1 | [dev-tools.md](dev-tools.md) |
| `firefox` | Firefox (everything-else browser) | host | по выбору | 1 | [browsers.md](browsers.md) |
| `chromium` | Chromium (for the Chromium-only sites) | host | по выбору | 1 | [browsers.md](browsers.md) |
| `zen` | Zen browser + Junction link picker | host | галочка стоит | 2 | [isolation-browser.md](isolation-browser.md) |
| `printing` | Printing (CUPS) | host | галочка стоит | 3 | [hardware.md](hardware.md) |
| `docker` | Docker + lazydocker | both | по выбору | 4 | [dev-tools.md](dev-tools.md) |
| `greeter` | Login screen: DMS greeter on greetd | host | галочка стоит | 2 | [greeter.md](greeter.md) |
| `go` | Go | both | по выбору | 1 | [dev-tools.md](dev-tools.md) |
| `dotnet` | .NET SDK + ASP.NET, freetds | both | галочка стоит | 7 | [dev-tools.md](dev-tools.md) |
| `rider` | JetBrains Rider | both | галочка стоит | 1 | [dev-tools.md](dev-tools.md) |
| `db-tools` | DB clients: DBeaver (GUI), lazysql, usql, sqlcmd (TUI) | both | галочка стоит | 4 | [dev-tools.md](dev-tools.md) |
| `api-tools` | API clients: Bruno (GUI), posting (TUI) | both | галочка стоит | 2 | [dev-tools.md](dev-tools.md) |
| `keepassxc` | Passwords: KeePassXC (local vault + Syncthing + phone) | host | галочка стоит | 1 | [secrets.md](secrets.md) |
| `claude` | Claude Code CLI | both | галочка стоит | 1 | [agents.md](agents.md) |
| `codex` | OpenAI Codex CLI | both | по выбору | 1 | [agents.md](agents.md) |
| `gh` | GitHub CLI | both | галочка стоит | 1 | [dev-tools.md](dev-tools.md) |
| `azure` | Azure CLI + azd | both | по выбору | 1 | [dev-tools.md](dev-tools.md) |
| `teams` | Teams for Linux | both | по выбору | 1 | [dev-tools.md](dev-tools.md) |
| `ziti` | OpenZiti edge tunnel | both | по выбору | 1 | [network.md](network.md) |
| `killswitch` | Kill-switch: drop egress that bypasses the VPN | container | по выбору | 0 | [killswitch.md](killswitch.md) |
| `voice` | Voice input (Handy, offline) | host | по выбору | 2 | [voice.md](voice.md) |
| `syncthing` | Syncthing: notes and phone media sync | host | галочка стоит | 3 | [sync.md](sync.md) |
| `obsidian` | Obsidian (notes editor) | host | галочка стоит | 1 | [sync.md](sync.md) |
| `wallpapers` | Wallpapers into ~/Pictures/wallpapers | host | галочка стоит | 0 | [desktop.md](desktop.md) |
| `bluetooth-fix` | Fix for cheap USB Bluetooth dongle (10d7:b012) | host | по выбору | 0 | [hardware.md](hardware.md) |

Пакеты посчитаны из всех источников фичи: pacman, AUR, npm, dotnet tool.
