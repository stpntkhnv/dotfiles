---
covers:
  features: [canvas]
  paths:
    - home/dot_config/driftwm/config.toml
---

# Desktop: driftwm + Noctalia (infinite canvas)

## What it does

Second host session beside niri ([desktop.md](desktop.md)), feature `canvas`,
asked and off by default. `driftwm` puts windows at native size on one infinite
2D canvas and navigates by moving the camera with trackpad gestures - no tiling,
no workspaces. `noctalia` (v5) is its shell: bar, launcher, lock, notifications.
2 AUR + 4 pacman packages. Meant for the laptop; a mouse-only machine gets the
model without the gestures.

## Files

| Path | Role |
|---|---|
| `home/dot_config/driftwm/config.toml` | the entire session: keyboard, trackpad, binds, autostart |
| runtime, from the `driftwm` package: `/usr/share/wayland-sessions/driftwm.desktop`, `/usr/bin/driftwm-session`, `/usr/lib/systemd/user/driftwm.service`, `/usr/share/xdg-desktop-portal/driftwm-portals.conf`, `/etc/driftwm/config.reference.toml` | session entry, login wrapper, unit, portal preferences, annotated defaults |
| runtime, not in the repo: `~/.config/noctalia/*.toml` (hand-written, read-only to the app), `~/.local/state/noctalia/settings.toml` (written by its GUI) | shell settings, see Decisions |
| runtime: `~/.local/state/driftwm/session.json` | saved canvas; also the "was it ever started" marker script `zz-next-steps` reads |

## How it works

- Login: greeter runs `driftwm.desktop` -> `driftwm-session`, which re-execs
  through a login shell, imports the environment into systemd and D-Bus, then
  `systemctl --user --wait start driftwm.service`. Logs are in the journal
  (`journalctl --user -u driftwm.service`), not on stderr.
- Shell: `autostart = ["noctalia"]` in our config. Noctalia identifies the
  compositor from env vars only - `NIRI_SOCKET`, `HYPRLAND_INSTANCE_SIGNATURE`,
  `SWAYSOCK`, then a `XDG_CURRENT_DESKTOP` substring match
  (`src/compositors/compositor_detect.cpp`, `detectImpl`). driftwm matches
  none, so it resolves to `CompositorKind::Unknown` and runs on the
  protocol-generic backends: `ext-workspace-v1` (driftwm exports its bookmarks
  as workspaces), `wlr-layer-shell`, output power. There is no driftwm-specific
  code in Noctalia - grepped the tree for `drift`, zero hits, 2026-08-04.
- Keyboard: this is the **third** independent copy of `us,ru` in the repo,
  after niri and `localectl`/TTY - [keyboard.md](keyboard.md).
- Portals: the package's `driftwm-portals.conf` sets `default=gtk` and points
  ScreenCast/Screenshot at `wlr`, hence `xdg-desktop-portal-wlr` in the feature;
  the gtk portal comes with `desktop`.
- Trying it without logging out: `driftwm` detects a running Wayland session and
  opens as a window. State is per-file there, so pass one:
  `driftwm --session-file ~/.local/state/driftwm/nested.json`.

## Constraints

- **`grp:alt_shift_toggle` must stay out of `[input.keyboard] options`.**
  driftwm reads a bare modifier chord as a tap binding; an xkb group toggle on
  the same chord swallows it. The layout switch is the `"alt+shift" =
  "switch-layout next"` binding instead - same keys, same result.
- **Never install the `noctalia-shell` (v4) package.** It depends on
  `noctalia-qs`, a Quickshell fork that `Conflicts` *and* `Provides`
  `quickshell` - installing it would swap the quickshell that `dms-shell-niri`
  and the DMS greeter run on for a fork, on a machine whose rescue path is that
  same DMS. v5 `noctalia` is a native Wayland/GL binary with no Qt at all
  (upstream `README.md`, "no Qt or GTK dependency"), so the two shells coexist
  and only one runs per session.
- **niri is not replaced and must not be.** driftwm's own README opens with
  "This is experimental software, primarily built with AI"; v0.16.0, repo
  created 2026-02-22 (checked 2026-08-04). `desktop` stays `always: true`, both
  sessions appear in the greeter menu.
- **Outputs wired to a discrete GPU do not light up.** PRIME/multi-GPU output
  support is unimplemented: [driftwm#91](https://github.com/malbiruk/driftwm/issues/91)
  and [#178](https://github.com/malbiruk/driftwm/issues/178) open,
  [#104](https://github.com/malbiruk/driftwm/issues/104) (identical Intel+NVIDIA
  "HDMI not detected") closed with no fix, all checked 2026-08-04. On a hybrid
  laptop the internal panel works, external HDMI probably will not.
- **Blur stays off.** It is opt-in per window rule and we set none: corruption
  on NVIDIA ([#249](https://github.com/malbiruk/driftwm/issues/249)), 90% GPU
  and 2 GB VRAM when zoomed out
  ([#125](https://github.com/malbiruk/driftwm/issues/125)).

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| Noctalia v5 beta | v4 drags in the quickshell fork (see Constraints); v5 has no Qt | `noctalia-shell` 4.7.7 |
| Noctalia over driftwm's bundled `extras/` | one shell to learn and configure, same class of thing as DMS | waybar + fuzzel + swaync |
| Shell settings not in the repo | its GUI writes `~/.local/state/noctalia/settings.toml` and treats `~/.config/noctalia/*.toml` as read-only, so a repo file cannot be clobbered the way DMS clobbers `cursor.kdl` - but which settings to pin is still unknown | committing a settings file now |
| `canvas` asked, `desktop` still `always` | both session entries coexist; niri is the way back from an experimental compositor | making the desktop a choice |
| `window_placement = "auto"` | on an infinite canvas the default `center` opens every window on the same spot | the default |
| `restore_*` all on | the canvas is the workspace; losing it on logout equals niri dropping every column | default (nothing restored) |

## Verify

```sh
driftwm --check-config                        # config is valid
pacman -Qq driftwm noctalia                   # both present
pacman -Qq noctalia-qs 2>/dev/null; echo $?   # 1 -- the quickshell fork must NOT be here
ls /usr/share/wayland-sessions/               # driftwm.desktop beside niri.desktop
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| Canvas comes up bare, no bar or launcher | noctalia did not start | run `noctalia` from a terminal, read `journalctl --user -u driftwm.service` |
| Alt+Shift stops switching layout | `grp:alt_shift_toggle` crept into `options` | drop it, keep the tap binding |
| External monitor stays dark | its connector hangs off the discrete GPU | internal panel only; upstream #91 |
| Flicker or a stuttering cursor | NVIDIA quirks are opt-in | `[backend] wait_for_frame_completion` / `disable_hardware_cursor`, or `SMITHAY_USE_LEGACY=1` before launch |
| X11 app will not start | `xwayland-satellite` missing | it comes with `desktop`; driftwm spawns it at startup unless `[xwayland] enabled` is false |

## See also

[desktop.md](desktop.md) (niri session), [greeter.md](greeter.md) (which lists
both), [keyboard.md](keyboard.md), [terminal.md](terminal.md),
[hardware.md](hardware.md).
