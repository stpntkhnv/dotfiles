# `distrobox-host-exec` never worked in these containers

Found 2026-07-29. Routed around 2026-07-30; the tool itself stays broken,
wontfix.

**Symptom** In `digi3`, `distrobox-host-exec echo hi` and `host-spawn echo hi`
exit 127 with empty stdout and stderr, for any command including `true`.
`host-spawn --version` prints v1.6.0 rc=0. Not a regression: the `xdg-open`
wrapper from `37-container-links` never once reached the host.

**Root cause** Two causes, both required. (A) `host-spawn` calls
`org.freedesktop.Flatpak.Development.HostCommand` (see `strings
/usr/bin/host-spawn`), served by `flatpak-session-helper`; `flatpak` is not in
the feature catalog and never was. (B) `distrobox-create` mounts the host
`/run/user/$UID` only when `init=0`, and `distrobox.ini.tmpl` sets
`init=true`, so the session bus address points at the container's own bus.
Fixing (B) alone still gives 127.

**Fix** `38-linkrouting` replaced the route with a `socat` listener per
context on `~/.local/share/wsproxy/<ctx>/links.sock`. Reviving
`distrobox-host-exec` needs `flatpak` plus a bus pointer, and `HostCommand`
grants any container arbitrary host execution.

**Recheck** `distrobox-host-exec true; echo $?` in a container still prints
127; `busctl --user list | grep Flatpak` on the host is empty.
