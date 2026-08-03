---
covers:
  features: []
  paths: []
---

# Isolation of work contexts

## What it does

Hub of the isolation cluster. Threat model: **an employer reading their own
logs must not get observable evidence that other jobs exist.** Vectors: shared
source IP, employer-visible DNS, cookies and sessions, logins to tenant-shared
services (`login.microsoftonline.com`). Hostile code inside a context is out of
scope (Constraints).

One browser process on the host; each tab exits through its context's netns.
"Container" is two things: distrobox/podman (netns, pid ns) and a Firefox
Multi-Account container (cookies). Names match by design: Firefox
`digi3` proxies to 11081, which bridges into distrobox `digi3`.

## How it works

Egress chain: Zen tab -> `context-proxy` extension -> host `socat` on
`127.0.0.1:<socks>` -> `~/.local/share/wsproxy/<ctx>/socks.sock` -> `socat` +
`microsocks` in the container -> killswitch if it has a VPN -> container netns.

`contexts:` in `home/.chezmoidata.yaml` is the source: `digi3` 11081,
`stellium` 11082, `personal` 11083. One name generates the `distrobox.ini`
section, socket dir, bridge unit, Zen container, space, bookmarks and picker
entry. `route: true` (digi3, stellium) makes Zen Space Routing pull URLs
containing the name into that space; `personal` lacks it deliberately - the
word occurs in ordinary URLs (`github.com/settings/personal-access-tokens`).

`plain_context:` (`home`, cyan, outside `context_palette`) is the no-job
space: Zen container, space and bookmarks, but no proxy, container or bridge -
traffic leaves from the host.

- [containers.md](containers.md) - the distrobox container
- [isolation-network.md](isolation-network.md) - the socket bridge
- [isolation-browser.md](isolation-browser.md) - Zen extensions, spaces
- [isolation-links.md](isolation-links.md) - links from outside
- [killswitch.md](killswitch.md)
- [nested-podman.md](nested-podman.md)

## Constraints

Reliable: netns and pid ns per container (`unshare_netns=true`,
`unshare_process=true`, `home/dot_config/distrobox/distrobox.ini.tmpl` `[base]`);
DNS resolved in-container (`proxyDNS: true`,
`run_onchange_after_41-zen-context-proxy.sh.tmpl`); cookies per Firefox
container; bridges bind `127.0.0.1` (`run_onchange_after_34-wsproxy-host.sh.tmpl`).

By convention only, or not at all:

- **Host filesystem visible.** distrobox mounts host `/` at `/run/host`, no switch against it: `digi3` can list `/run/host/home/stsiapan/homes/` (proof other contexts exist) and dial a neighbour's `socks.sock`, leaving through the wrong netns.
- **`/tmp`, `/dev/shm`, `/dev` shared**, the last two deliberately (`unshare_ipc=false`, `unshare_devsys=false`): podman's 64M `/dev/shm` breaks Electron and JVM apps, dropping `/dev` costs GPU and sound. No `/tmp` switch exists; none helps against attribution.
- **Tabless requests bypass the proxy**: `if (info.tabId < 0) { return {}; }` in `handler`, script 41.
- **WebRTC media leaves the host directly** (Decisions): a work-tab call shows the home IP.
- **One public IP until a per-context VPN exists**; the repo ships the killswitch, not the VPN.
- **One git identity**: `promptStringOnce . "git_email"`, `home/.chezmoi.toml.tmpl`; per-context homes prompt separately, answers match in practice.
- **Hand-typed URLs in a foreign space** exit through that space's netns; routing covers only links from outside.
- **`home` shares one cookie jar** between throwaway links and logged-in sessions; accepted, it belongs to no job.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| One host browser, per-tab egress | All jobs in one window | Firefox per container: separate instances miss `browser.slice` 6G/8G (zen 5G/6G) |
| `media.peerconnection.ice.proxy_only` absent (2026-07-31) | Profile-wide pref killed calls in every space, Firefox cannot push media through SOCKS; home IP ruled not confidential | Keeping it, losing all calls |

## Verify

```sh
distrobox enter digi3 -- readlink /proc/self/ns/net   # differs from host
systemctl --user is-active wsproxy-digi3.service      # active
curl -sx socks5h://127.0.0.1:11081 https://ifconfig.me # digi3 netns egress IP
```
