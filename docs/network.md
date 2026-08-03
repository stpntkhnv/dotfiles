---
covers:
  features: [tailscale, ziti]
  paths:
    - home/.chezmoiscripts/run_onchange_before_60-ziti.sh.tmpl
    - home/bin/executable_update-ziti-hosts.sh.tmpl
    - home/.chezmoiscripts/run_onchange_before_30-system.sh.tmpl
---

# Host network: Tailscale, OpenZiti, ufw

## What it does

Feature `tailscale` (`scope: host`, `always: true`), feature `ziti`
(`scope: both`, opt-in, AUR `ziti-edge-tunnel`), and ufw, which has no feature
key: package from `host-base`, policy from `30-system`. Container egress:
[killswitch.md](killswitch.md).

## Files

| Path | Role |
|---|---|
| `home/.chezmoiscripts/run_onchange_before_30-system.sh.tmpl` | last third: ufw policy, holes, `tailscaled`; host only (`ne .env "host"`). Earlier thirds: [keyboard.md](keyboard.md), [hardware.md](hardware.md) |
| `home/.chezmoiscripts/run_onchange_before_60-ziti.sh.tmpl` | ziti identity dir + unit; no packages, no `.env` check |
| `home/bin/executable_update-ziti-hosts.sh.tmpl` | hand-run tool; whole body under `if has "ziti" .enabled` |
| runtime (ziti) | `/etc/systemd/system/ziti-edge-tunnel.service` shadows the AUR unit; `/opt/openziti/etc/identities/` starts empty; `/etc/hosts` `BEGIN/END ziti-dns-entries` |

## How it works

- Tailscale: `enable_unit tailscaled.service` plus an explicit `start` if not
  active - the only started unit here. Manual `sudo tailscale up`
  (browser auth), nagged by `run_after_zz-next-steps.sh.tmpl` while
  `tailscale status` fails. No daemon in containers.
- `60-ziti` is identical on host and in a container; the gate is only whether
  `ziti` is ticked there. `enable` without `--now`: with no identity there is
  nothing to tunnel, and the checklist nags while the dir is empty.
- OpenZiti has no kill-switch: `39-killswitch` covers one IPv4 endpoint on one
  interface and says so - "OpenZiti does not fit this shape at all".
- `update-ziti-hosts.sh` greps `journalctl -u ziti-edge-tunnel --since "7 days
  ago"` for `registered DNS entry <name> -> <ip>`, rewrites the marked
  `/etc/hosts` block, drops older lines naming those hosts. Non-root is a dry
  run. Nothing calls it.
- Firewall: `default deny incoming` / `allow outgoing` / `--force enable`, once.
  Holes: `printing` -> `ufw allow mdns`; `syncthing` -> `22000/tcp`, `22000/udp`,
  `21027/udp`.

## Constraints

- Rules are added, never removed - no `ufw delete` anywhere. Unticking a feature
  stops the check, not the open port.
- `ufw allow mdns` opens tcp/5353 **and** udp/5353: `mdns` is an `/etc/services`
  name with both entries, not a ufw profile. The comment says udp only.
- Each `sudo ufw` call is guarded by a `ufw status` grep, else apply prompts for
  a password on every run.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| `tailscaled` enabled **and** started | next-steps `tailscale up` needs a live daemon; a reboot in between loses the reader | enable-only, as every other unit here |
| holes are port-only, any source | interface name is not guaranteed, home network changes; Syncthing checks the peer cert fingerprint per connection ([Security](https://docs.syncthing.net/users/security.html)) | `ufw allow in on tailscale0` |
| own ziti unit replaces the package's | AUR unit runs `User=ziti` + `ExecStartPre=ziti-edge-tunnel-enroll` (polkit); here identities are finished files (PKGBUILD read 2026-07-31). Its `AmbientCapabilities=CAP_NET_ADMIN` is copied along, a no-op at UID 0 | package unit + enroll |

## Verify

```sh
tailscale status  # lists the user's machines (2026-07-31)
sudo ufw status verbose  # deny/allow + 5353 tcp&udp, 22000 tcp&udp, 21027 udp (2026-07-31)
systemctl is-enabled ziti-edge-tunnel.service  # enabled where ziti is on
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| machines missing from `tailscale status` | `tailscale up` never done, or daemon down | run it; else `journalctl -u tailscaled` |
| `ziti-edge-tunnel` restart-loops (`RestartSec=3`) | no identity JSON | copy it in, restart the unit |
| `update-ziti-hosts.sh` exits 1 | no journal hits: tunnel down or journal older than 7 days | check the unit |

## See also

[base.md](base.md), [sync.md](sync.md),
[isolation-network.md](isolation-network.md).
