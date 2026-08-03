# dotfiles

Arch Linux workstation configuration managed with [chezmoi](https://www.chezmoi.io/).

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/stpntkhnv/dotfiles/main/install.sh)"
```

## Install

The command above installs chezmoi if needed, clones this repo, shows the
feature checklist, installs what was selected and lays down the configs. It
behaves the same on a bare host and inside a distrobox container - the
environment is detected from the presence of `/run/.containerenv`.

If the CDN serves a stale `install.sh`, fetch the same file through the GitHub
API instead:

```sh
sh -c "$(curl -fsSL https://api.github.com/repos/stpntkhnv/dotfiles/contents/install.sh -H 'Accept: application/vnd.github.raw')"
```

Non-interactive installs, changing a choice already made, and the sharp edges
of `chezmoi init --prompt` are in [`docs/install.md`](docs/install.md).

## What lands on the machine

Eight features are unconditional (`always: true`), because the machine does not
work without them: `core` and `shell` (base utilities and the shell - `git`,
`ssh`, starship, eza, bat, fzf, zoxide), `host-base` (host plumbing),
`earlyoom` (memory watchdog), `desktop` (niri + DankMaterialShell), `tailscale`
(network between own machines), `distrobox` (work-context containers) and
`container-base` (in-container plumbing such as locale-gen and xauth). They are
described in [`docs/base.md`](docs/base.md),
[`docs/desktop.md`](docs/desktop.md), [`docs/hardware.md`](docs/hardware.md),
[`docs/network.md`](docs/network.md) and
[`docs/containers.md`](docs/containers.md).

The other 30 come from a checklist; 17 of them are pre-checked, including the
`zen` browser that carries the work-context isolation
([`docs/isolation-browser.md`](docs/isolation-browser.md)). `home/.chezmoidata.yaml`
lists 38 features in total, each with its own packages and a `scope` (host /
container / both). During install the checklist can be edited (space toggles,
Enter confirms) and the choice is saved to `~/.config/chezmoi/chezmoi.toml`.
The full table with the unconditional ones marked is
[`docs/catalog.md`](docs/catalog.md); how the catalogue works and how to add a
feature is [`docs/how-it-works.md`](docs/how-it-works.md).

## Access tokens

Agents working in this repo have access to neither passwords nor personal
access tokens. There used to be a `pat` command reading them from Bitwarden;
that scheme was removed on 2026-08-01. Each organisation's personal access
token is now copied by hand from its site at the moment it is needed.

Passwords live in KeePassXC - one local file synced to every machine through
Syncthing. How that is wired and what to do when it breaks:
[`docs/secrets.md`](docs/secrets.md).

## Docs

Everything under `docs/` is written in English for AI agents: dense, factual,
no tutorials. Start from the map, [`docs/README.md`](docs/README.md). The
format they follow is [`docs/STYLE.md`](docs/STYLE.md).
