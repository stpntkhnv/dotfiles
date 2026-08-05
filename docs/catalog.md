# Feature catalogue

<!-- GENERATED FILE. Hand edits are wiped.
     Source: home/.chezmoidata.yaml and the covers headers in docs/*.md
     Rebuild: tools/gen-catalog.sh -->

All 39 features. The Doc column leads to the detailed description.

| Feature | What | Where | How enabled | Packages | Doc |
|---|---|---|---|---|---|
| `core` | Base utilities | both | always | 21 | [base.md](base.md) |
| `shell` | Shell: starship, eza, bat, fzf, zoxide, ripgrep, fd | both | always | 9 | [base.md](base.md) |
| `container-base` | Container plumbing | container | always | 12 | [containers.md](containers.md) |
| `host-base` | Host essentials: network, Bluetooth, firewall, zram | host | always | 12 | [base.md](base.md) |
| `earlyoom` | earlyoom: kill one process instead of hanging the machine | host | always | 1 | [hardware.md](hardware.md) |
| `desktop` | Desktop: niri + DankMaterialShell | host | always | 32 | [desktop.md](desktop.md) |
| `tailscale` | Tailscale VPN | host | always | 1 | [network.md](network.md) |
| `distrobox` | distrobox + podman | host | always | 2 | [containers.md](containers.md) |
| `canvas` | Desktop: driftwm + Noctalia (infinite canvas, laptop) | host | opt-in | 6 | [desktop-canvas.md](desktop-canvas.md) |
| `herdr` | herdr: agent-aware multiplexer (primary) | both | pre-checked | 1 | [multiplexer.md](multiplexer.md) |
| `tmux` | tmux (fallback multiplexer) | both | pre-checked | 1 | [multiplexer.md](multiplexer.md) |
| `neovim` | Neovim + LSP, treesitter | both | pre-checked | 2 | [dev-tools.md](dev-tools.md) |
| `node` | Node.js + npm | both | pre-checked | 2 | [dev-tools.md](dev-tools.md) |
| `vscode` | VS Code + extensions from extensions.txt | both | opt-in | 1 | [dev-tools.md](dev-tools.md) |
| `firefox` | Firefox (everything-else browser) | host | opt-in | 1 | [browsers.md](browsers.md) |
| `chromium` | Chromium (for the Chromium-only sites) | host | opt-in | 1 | [browsers.md](browsers.md) |
| `zen` | Zen browser + Junction link picker | host | pre-checked | 2 | [isolation-browser.md](isolation-browser.md) |
| `printing` | Printing (CUPS) | host | pre-checked | 3 | [hardware.md](hardware.md) |
| `docker` | Docker + lazydocker | both | opt-in | 4 | [dev-tools.md](dev-tools.md) |
| `nested-podman` | Podman-in-box: containers inside the context (Aspire, Testcontainers) | container | opt-in | 4 | [nested-podman.md](nested-podman.md) |
| `greeter` | Login screen: DMS greeter on greetd | host | pre-checked | 2 | [greeter.md](greeter.md) |
| `go` | Go | both | opt-in | 1 | [dev-tools.md](dev-tools.md) |
| `dotnet` | .NET SDK + ASP.NET, freetds | both | pre-checked | 7 | [dev-tools.md](dev-tools.md) |
| `rider` | JetBrains Rider | both | pre-checked | 1 | [dev-tools.md](dev-tools.md) |
| `db-tools` | DB clients: DBeaver (GUI), lazysql, usql, sqlcmd (TUI) | both | pre-checked | 4 | [dev-tools.md](dev-tools.md) |
| `api-tools` | API clients: Bruno (GUI), posting (TUI) | both | pre-checked | 2 | [dev-tools.md](dev-tools.md) |
| `keepassxc` | Passwords: KeePassXC (local vault + Syncthing + phone) | host | pre-checked | 1 | [secrets.md](secrets.md) |
| `claude` | Claude Code CLI | both | pre-checked | 1 | [agents.md](agents.md) |
| `codex` | OpenAI Codex CLI | both | opt-in | 1 | [agents.md](agents.md) |
| `gh` | GitHub CLI | both | pre-checked | 1 | [dev-tools.md](dev-tools.md) |
| `azure` | Azure CLI + azd | both | opt-in | 1 | [dev-tools.md](dev-tools.md) |
| `teams` | Teams for Linux | both | opt-in | 1 | [dev-tools.md](dev-tools.md) |
| `ziti` | OpenZiti edge tunnel | both | opt-in | 1 | [network.md](network.md) |
| `killswitch` | Kill-switch: drop egress that bypasses the VPN | container | opt-in | 0 | [killswitch.md](killswitch.md) |
| `voice` | Voice input (Handy, offline) | host | opt-in | 2 | [voice.md](voice.md) |
| `syncthing` | Syncthing: notes and phone media sync | host | pre-checked | 3 | [sync.md](sync.md) |
| `obsidian` | Obsidian (notes editor) | host | pre-checked | 1 | [sync.md](sync.md) |
| `wallpapers` | Wallpapers into ~/Pictures/wallpapers | host | pre-checked | 0 | [desktop.md](desktop.md) |
| `bluetooth-fix` | Fix for cheap USB Bluetooth dongle (10d7:b012) | host | opt-in | 0 | [hardware.md](hardware.md) |

Package counts add up pacman, AUR, npm and dotnet tool sources.
