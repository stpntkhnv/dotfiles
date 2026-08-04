---
covers:
  features: [desktop, wallpapers]
  paths:
    - home/dot_config/niri/config.kdl
    - home/dot_config/niri/dms/**
    - home/dot_config/DankMaterialShell/settings.json
    - home/.chezmoiscripts/run_after_80-niri-dms-placeholders.sh.tmpl
    - home/Pictures/wallpapers/**
---

# Desktop: niri + DankMaterialShell

## What it does

Host Wayland session: `niri` (scrolling compositor, no UI of its own) plus DMS
(DankMaterialShell - bar, launcher, lock), which drives niri over IPC and writes part of
its config. `desktop` is `always: true`, 32 packages; `wallpapers` gates 3 JPEGs.

## Files

| Path (`home/`) | Role |
|---|---|
| `dot_config/niri/config.kdl` | `xkb` ([keyboard.md](keyboard.md)), 8 `window-rule`, `xwayland-satellite :12`, 7 `include` |
| `dot_config/niri/dms/**` | `binds.kdl` (ours), `cursor.kdl` (stub, see Constraints), `empty_windowrules.kdl` (0-byte, `empty_`) |
| `dot_config/DankMaterialShell/settings.json` | DMS settings, committed whole |
| `Pictures/wallpapers/**` | 3 JPEGs, 7.0 MB; `.chezmoiignore` drops `Pictures/**` when off |
| `.chezmoiscripts/run_after_80-niri-dms-placeholders.sh.tmpl` | Creates missing includes |

## How it works

- Six `include "dms/*.kdl"` plus `include "voice.kdl"` ([voice.md](voice.md); valid empty
  KDL when voice is off). Four (`colors`, `layout`, `alttab`, `outputs`) are written by DMS
  at runtime (`Services/NiriService.qml`) and stay out of the repo: chezmoi would revert
  them on every theme change.
- Script 80 greps that list out of `config.kdl`, not hardcoding it
  (`grep -oP '^\s*include\s+"\K[^"]+'`), writing a comment-line placeholder per missing
  target and logging `==> Created placeholder`. Verified 2026-07-31: an unseen `include`
  produced its file.
- Active wallpaper is DMS session state (`~/.local/state/DankMaterialShell/session.json`,
  `wallpaperPath`), not repo.

## Constraints

- **`dms/windowrules.kdl` and `dms/wpblur.kdl` exist; nothing includes them.**
  DMS-UI rules and the blur toggle do nothing; the 8 live rules are inline.
- **`cursor.kdl` is not as safe as `binds.kdl`.** `generateNiriCursorConfig`
  (NiriService.qml) overwrites it once `cursorSettings` leave their defaults, and
  `updateCompositorCursor()` (`Common/SettingsData.qml`) fires on DMS start and from the
  `watchChanges: true` FileView on `settings.json` - which `chezmoi apply` trips. Intact
  only because `cursorSettings` are still default (`"System Default"`/`24`). In the repo
  by accident (`8c9964b`), not by decision.
- **niri 26.04 supports `include optional=true`, unused here** (`grep -c optional=true` ->
  `0`), so script 80 is all that keeps a clean machine off bare niri
  ([workarounds.md](workarounds.md)).

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| Six "optional" DMS deps unconditional | A missing one is a silently dead widget | A checklist question |
| No wallpaper set on apply | DMS owns the choice (`Mod+Y`) | A repo default overriding the user |

That comment cites `dms-shell`, but `dms-shell-niri` is installed (`Optional Deps:
None`); `kimageformats` is in neither, `tuned-ppd` only as `power-profiles-daemon`.
`brightnessctl` is unused (2026-07-31: absent from `home/` and the `dms` binary).

## Verify

```sh
niri validate -c ~/.config/niri/config.kdl  # INFO niri: config is valid
grep -n 'windowrules\|wpblur' home/dot_config/niri/config.kdl  # empty = orphans
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| Clean machine boots into bare niri, no bar | script 80 never ran, `dms/*.kdl` missing | `chezmoi apply`, expect `==> Created placeholder` |

## See also

[desktop-canvas.md](desktop-canvas.md) (the other session, `canvas`),
[greeter.md](greeter.md) (same shell), [keyboard.md](keyboard.md), [voice.md](voice.md),
[browsers.md](browsers.md), [base.md](base.md) (`ttf-jetbrains-mono-nerd` comes with
`desktop`, not `shell`).
