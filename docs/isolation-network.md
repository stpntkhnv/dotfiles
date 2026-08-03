---
covers:
  features: []
  paths:
    - home/.chezmoiscripts/run_onchange_after_34-wsproxy-host.sh.tmpl
    - home/.chezmoiscripts/run_onchange_before_15-wsproxy-container.sh.tmpl
    - home/.chezmoiscripts/run_after_35-bridges-up.sh.tmpl
---

# wsproxy bridge

## What it does

Carries host browser traffic into one work context's netns over a UNIX socket,
publishing no port. One chain per context, host and container halves. No
feature key: `socat`/`microsocks` ship with `host-base`/`container-base`.

## Files

| Path | Role |
|---|---|
| `home/.chezmoiscripts/run_onchange_after_34-wsproxy-host.sh.tmpl` | Host: validate `contexts:`, prune, write+enable the units |
| `home/.chezmoiscripts/run_onchange_before_15-wsproxy-container.sh.tmpl` | Container: `gai.conf`, both units |
| `home/.chezmoiscripts/run_after_35-bridges-up.sh.tmpl` | Host, every apply: start down bridge units |
| `contexts:` in `home/.chezmoidata.yaml` | Names, `socks` ports: digi3 11081, stellium 11082, personal 11083 |

## How it works

- Chain: tab -> host `socat TCP-LISTEN:<socks>,bind=127.0.0.1,fork,reuseaddr`
  -> `socks.sock` -> container `socat UNIX-LISTEN:...,mode=600,unlink-early` ->
  `microsocks -i 127.0.0.1 -p 1080` -> container netns, resolver, VPN. Only
  microsocks speaks SOCKS5; the two `127.0.0.1` differ. The port is also
  compiled into the extension (script 41, `proxyDNS: true`).
- Script 34 validates the table first: duplicate name (both contexts get one
  socket dir and volume, a leak decided by yaml order, not a race), duplicate
  port (second unit never binds, browser keeps the first) or the
  `plain_context` name (`grep -ix`) abort the apply.
- Script 15 exits 0 if `/var/lib/wsproxy` is unmounted (container predates the
  volume). It runs at `before-15` (was `after-36` until 2026-08-01) and installs
  `socat microsocks` itself: later setup needs the browser in this space, which
  has no network until the bridge is up.
- Script 35 exists because 34 and 38 are `onchange`: recreating containers on
  2026-08-01 stopped every bridge, nothing restarted them. Never fails apply.

## Constraints

- Prune before create in 34: a renamed context reusing its port needs it freed
  first; `reuseaddr` only speeds one process's rebind.
- All three units carry `User={{ .chezmoi.username }}`: `keep-id` maps container
  uid 1000 to host uid 1000 but container root to subuid 100000 (`uid_map` of
  digi3, 2026-07-30), so a root-owned `mode=600` socket is EACCES on the host.
- Container units are system units: systemd runs as init, no logind session,
  no user manager. `wsproxy-bridge` has `Requires=`/`After=wsproxy-socks`.
- Socket dir is per context, `mode 700`; shared, any container could dial a
  neighbour's proxy. Not a boundary even so: `/run/host` puts every context's
  dir inside every container ([isolation.md](isolation.md)). In `/var/lib`, not
  `/mnt` - [workarounds.md](workarounds.md).
- `SuccessExitStatus=143` on the host unit: socat exits 143 on SIGTERM.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| UNIX socket | No route or port at the netns boundary; the host dials in, the container has no address for it | Port publishing |
| Units generated | Names and ports would exist twice, then drift | Checked-in `.service` |
| IPv4-first `gai.conf` | microsocks tries only the first address; `localhost` -> `::1` broke OAuth callbacks of CLIs bound to `127.0.0.1` (`claude`, `codex`) - [workarounds.md](workarounds.md) | Patching each CLI |

## Verify

```sh
ss -ltn | grep -E ':1108[0-9]'            # one LISTEN per context
ls -l ~/.local/share/wsproxy/*/*.sock     # srw-------, user-owned
# Which netns each port exits (2026-07-30: digi3, stellium, personal):
for c in digi3 stellium personal; do podman exec -d "$c" socat TCP-LISTEN:8099,bind=127.0.0.1,fork,reuseaddr SYSTEM:"printf 'HTTP/1.0 200 OK\r\n\r\n$c\n'"; done
curl -s http://127.0.0.1:8099/; echo "exit=$?"   # 7 = nothing on the host; else the answers below prove nothing
for p in 11081 11082 11083; do curl -s --socks5-hostname "127.0.0.1:$p" http://127.0.0.1:8099/; done
for c in digi3 stellium personal; do podman exec "$c" pkill -f TCP-LISTEN:8099; done
```

Host `/tmp` is shared with containers (device `0:44`, 2026-07-30): never name a
container from a file there.

`podman exec -d`, not backgrounded `distrobox enter`: `-d` assumes nothing about
the client; client death did not kill it anyway (2026-07-30, distrobox 1.8.2.5,
podman 6.0.2).

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| One context has no network | A unit is down or the container is stopped | `systemctl --user status wsproxy-<ctx>`, the same inside for `wsproxy-socks`/`-bridge` |
| All bridges down or `failed` after a teardown | `onchange` did not re-run ([isolation-links.md](isolation-links.md)) | `chezmoi apply`: 35 starts them |
| Port changed, browser gets silence | Unit rewritten, not restarted: `enable --now` on an active unit is no restart (2026-07-30) | `systemctl --user restart wsproxy-<ctx>` |
| Old port still LISTENs, no unit | Renamed context: prune's `disable --now` swallows the stop error, `rm -f` runs anyway, the `socat` lives on | `ss -ltnp \| grep <port>`, kill by PID, re-apply |
| CLI login on `localhost:<port>` fails | No `/etc/gai.conf`, or `wsproxy-socks` not restarted since | `getent ahosts localhost` inside; `::1` first means apply, restart |

## See also

- [isolation.md](isolation.md) - threat model, whole chain.
- [containers.md](containers.md) - volume, container build.
- [isolation-browser.md](isolation-browser.md), [killswitch.md](killswitch.md).
