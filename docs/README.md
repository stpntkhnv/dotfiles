---
covers:
  features: []
  paths: []
---

# Doc map

One doc, one topic. Written for agents: dense, English, no tutorials - the
format is [`STYLE.md`](STYLE.md).

Three ways in:

- Know a feature key from `home/.chezmoidata.yaml` (`zen`, `killswitch`) - go to
  [`catalog.md`](catalog.md), the generated "feature -> doc" table.
- Hit a word this repo uses in its own way (`context`, `space`, `wsproxy`) -
  [`glossary.md`](glossary.md).
- Want a bug that was already investigated - [`issues/`](issues/), one file per
  investigation with dates and evidence.

## Machinery

- [`how-it-works.md`](how-it-works.md) - how chezmoi is wired here: the feature
  catalogue as single source of truth, script ordering, what re-runs when.
- [`install.md`](install.md) - installing on a clean machine, what the checklist
  asks, non-interactive installs, changing a saved choice.
- [`STYLE.md`](STYLE.md) - the standard every doc here follows.

## Isolation

- [`isolation.md`](isolation.md) - threat model and the overall picture; what is
  isolated reliably and what only by convention.
- [`containers.md`](containers.md) - the distrobox containers behind each work
  context.
- [`isolation-network.md`](isolation-network.md) - the socat/UNIX-socket bridge
  between the host browser and the network inside a container.
- [`isolation-browser.md`](isolation-browser.md) - Zen, Multi-Account
  Containers, and binding a space to a container's proxy.
- [`isolation-links.md`](isolation-links.md) - routing an external link into the
  right context.
- [`killswitch.md`](killswitch.md) - default-drop egress that kills traffic
  bypassing a container's VPN.
- [`nested-podman.md`](nested-podman.md) - podman inside a context, so Aspire
  and Testcontainers run on that context's localhost.

## Workspace

- [`base.md`](base.md) - base utilities, shell, git, prompt.
- [`desktop.md`](desktop.md) - niri, DankMaterialShell, wallpapers.
- [`desktop-canvas.md`](desktop-canvas.md) - the second session: driftwm's
  infinite canvas with Noctalia, for the laptop.
- [`greeter.md`](greeter.md) - login screen: greetd with the DMS greeter.
- [`terminal.md`](terminal.md) - ghostty and alacritty, themes.
- [`keyboard.md`](keyboard.md) - layout and its protection from `localectl`.
- [`multiplexer.md`](multiplexer.md) - herdr, tmux, and the `work` script.
- [`browsers.md`](browsers.md) - browser systemd slices, memory caps, launchers.

## Voice

- [`voice.md`](voice.md) - offline dictation through Handy: hotkeys, model,
  typing the recognised text.

## Data and network

- [`sync.md`](sync.md) - Syncthing and Obsidian: which folders sync where.
- [`network.md`](network.md) - Tailscale, OpenZiti, firewall.
- [`secrets.md`](secrets.md) - KeePassXC and SSH keys.

## Tools

- [`dev-tools.md`](dev-tools.md) - neovim, VS Code, node, go, dotnet, rider, DB
  and API clients, docker, azure, teams, gh.
- [`agents.md`](agents.md) - what this repo lays down for Claude Code and Codex.

## Hardware

- [`hardware.md`](hardware.md) - printing, the Bluetooth dongle bug, NVIDIA,
  zram, earlyoom.

## Operations

- [`workarounds.md`](workarounds.md) - registry of other people's bugs this repo
  works around: whose bug, what the evidence is, how to tell it is still alive.
- [`operations.md`](operations.md) - manual steps, diagnosis commands, and what
  `tools/gen-catalog.sh` does and does not check.
