---
covers:
  features: [nested-podman]
  paths:
    - home/.chezmoiscripts/run_onchange_after_36-nested-podman.sh.tmpl
---

# Nested podman

## What it does

Feature `nested-podman`, scope `container`: rootless podman and docker CLI in a
work context, so Aspire's DCP, Testcontainers and `docker run` get containers on
its `127.0.0.1`, unreachable from host or siblings.

## Files

| Path | Role |
|---|---|
| `home/.chezmoiscripts/run_onchange_after_36-nested-podman.sh.tmpl` | subuid/subgid, tmpdir drop-in, `podman.socket` |
| `home/.chezmoidata.yaml`, key `nested-podman` | `podman`, `docker` (CLI), `crun`, `passt` |
| `home/dot_bashrc.tmpl`, `has "nested-podman"` | `DOCKER_HOST`, `DOCKER_BUILDKIT=0` (compat API has no BuildKit) |

## How it works

Three fixes, reasons in the script: subuid `1001:64535` (distrobox maps exactly
65536 IDs; shadow's 100000+ makes `newuidmap` fail EPERM - the whole "nested
podman does not work" myth); `TMPDIR` off the container overlayfs, where buildah
cannot overlay-mount a build context; `podman.socket` as a *user* unit.

Storage `~/.local/share/containers` sits under the context home (`home=` in
`dot_config/distrobox/distrobox.ini.tmpl`), not the host's.

## Constraints

- `rm -rf ~/.local/share/containers` is safe only when `$HOME` is a context
  home: in a box lacking `home=` it wiped *host* podman storage, all contexts
  recreated (2026-08-03, volumes survived).
- 64535 UIDs per container; a third nesting level has no range left.
- Containers die with the context; volumes survive. They share its cgroup and
  `--memory=8g` with builds and tests.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| podman inside the context | dev tools assume container and process share a localhost | Host podman over `/run/host/.../podman.sock`: Aspire's DCP always creates a bridge network and connects every container to it, so they land in the host netns the context cannot reach, and host `127.0.0.1` publishes are invisible to it. `--network container:<box>` fails the same way: DCP cannot attach it to the bridge. |
| `crun` explicit | docker CLI sends `PidsLimit=0`; runc >= 1.4 reads it literally and the container gets `pids.max=1`, dying on its first fork | `runc` |

## Verify

```sh
podman run -d --name probe -p 127.0.0.1:18080:80 docker.io/library/nginx:alpine
curl -so /dev/null -w '%{http_code}\n' http://127.0.0.1:18080/  # 200; refused on host
podman rm -f probe
docker build .  # compat+TMPDIR
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `newuidmap ... EPERM` | shadow default in `/etc/subuid` | rerun apply |
| `userxattr: invalid argument` | tmpdir drop-in gone | restart `podman.service` |

## See also

[workarounds.md](workarounds.md) (crun vs runc, buildah TMPDIR),
[containers.md](containers.md).
