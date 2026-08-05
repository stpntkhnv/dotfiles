---
covers:
  features: [distrobox, container-base]
  paths:
    - home/dot_config/distrobox/distrobox.ini.tmpl
    - home/.chezmoiscripts/run_onchange_before_10-bootstrap-pacman.sh.tmpl
    - home/.chezmoiscripts/run_onchange_before_30-system.sh.tmpl
---

# distrobox containers

## What it does

Per-context container assembly. Features: `distrobox` (host: `distrobox` +
`podman`), `container-base` (container, 12 pkgs); both `always`. Why:
[isolation.md](isolation.md).

## Files

| Path | Role |
|---|---|
| `home/dot_config/distrobox/distrobox.ini.tmpl` | `[base]` + per-context sections |
| `.chezmoiscripts/run_onchange_before_10-bootstrap-pacman.sh.tmpl` | container-only pacman fixup |
| `.chezmoiscripts/run_onchange_before_30-system.sh.tmpl` | host-only; enables user `podman.socket` |

## How it works

- `distrobox assemble create --name <ctx> --file ~/.config/distrobox/distrobox.ini`
- `init=true`: systemd inside runs the bridge units
  ([isolation-network.md](isolation-network.md))
- Per context: `--memory=8g` (resource protection, not anti-attribution) plus
  `--volume ~/.local/share/wsproxy/<ctx>:/var/lib/wsproxy` — the only host
  channel, per-context by design.
- Host socket `/run/user/1000/podman/podman.sock` is, inside,
  `/run/host/run/user/1000/podman/podman.sock` (`--userns keep-id`); client:
  feature `docker` ([dev-tools.md](dev-tools.md)), no daemon inside.

## Constraints

- `--name` is mandatory: assemble builds one per section, `[base]` included —
  without it a junk `base` container appears.
- Rootless podman scopes join the `user.slice` 12G/16G cap ([agents.md](agents.md)).

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| `unshare_ipc`/`devsys` false | GPU, sound, podman's 64M shm (see ini) | unsharing; cost not re-measured |
| volume under `/var/lib` | `/mnt` remount hides it | `/mnt`; no upstream match, searched 2026-07-30 (#778, #1020, #1527, #2036 adjacent) |
| host podman socket kept | ok without shared localhost (Testcontainers + `TESTCONTAINERS_HOST_OVERRIDE`) | as Aspire's engine: containers land in host netns, dead end 2026-08-03 ([nested-podman.md](nested-podman.md)) |
| keep `10-bootstrap-pacman` | idempotent, cheap | dropping: fresh `archlinux:latest` (2026-07-30) had mirrors and `Include` already — guard unproven |

## Verify

```sh
# Server half must say podman
DOCKER_HOST=unix:///run/host/run/user/1000/podman/podman.sock docker version
uname -r; pacman -Q linux; grep -c overlay /proc/filesystems
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `'overlay' is not supported over extfs` | `linux` upgraded, no reboot: `CONFIG_OVERLAY_FS=m`, module went with the old modules dir | reboot. Arch wontfix: FS#16702, FS#23809, FS#73043 |
| volume "mounted but not there" | `distrobox-init` remounts host `/mnt`, `/media`, `/run/media`, `/var/mnt` every start, no opt-out (1.8.2.5 source, 2026-07-30) | keep `/var/lib/wsproxy` |
| clipboard reads empty inside | no `wl-paste`/`xclip` in the container; the Wayland socket is fine (`/run/user/1000/wayland-1 -> /run/host/...`) | `wl-clipboard` in `container-base` since 2026-08-05 ([agents.md](agents.md)) |

## See also

[workarounds.md](workarounds.md) rows: `/mnt`, mirrorlist, overlay.
