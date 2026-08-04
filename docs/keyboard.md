---
covers:
  features: []
  paths:
    - home/.chezmoiscripts/run_onchange_before_30-system.sh.tmpl
---

# Keyboard

## What it does

Host only, no feature key. `us,ru` + `grp:alt_shift_toggle,ctrl:swapcaps` on
the two surfaces niri does not cover: X11 (Xorg/Xwayland/sddm) and TTY.
Session [desktop.md](desktop.md), greeter [greeter.md](greeter.md).

## Files

| Path | Role |
|---|---|
| `home/.chezmoiscripts/run_onchange_before_30-system.sh.tmpl` | `# ---- keyboard ----` block; rest: zram/services/ufw ([hardware.md](hardware.md), [network.md](network.md)) |

## How it works

- Layout string exists three times, independently: here,
  `home/dot_config/niri/config.kdl` (`xkb {`), and - when the `canvas` feature
  is on - `home/dot_config/driftwm/config.toml` (`[input.keyboard]`,
  [desktop-canvas.md](desktop-canvas.md)). The third copy carries
  `ctrl:swapcaps` **without** `grp:alt_shift_toggle`: driftwm reads a bare
  modifier chord as a tap binding, so the group toggle would eat it, and the
  same keys are bound there as `"alt+shift" = "switch-layout next"`.
- X11 step diffs `localectl status` first: `set-x11-keymap` needs sudo,
  unguarded it prompts on every apply.
- Map failing the `loadkeys --mktable` check: `vconsole.conf` untouched.

## Constraints

- `--no-convert` mandatory: `kbd-model-map` has no `swapcaps` entry, so the
  conversion settles on plain `us` and clobbers the console map.
- `include` in the map must be absolute: `loadkeys` never searches
  `keymaps/i386/qwerty/`, home of `us.map.gz`. Proven in
  [workarounds.md](workarounds.md).
- No Russian in the TTY on purpose: it needs a map like `ruwin_ctrl` whose
  toggle collides with the Caps/Ctrl swap.
- `XKBLAYOUT=`/`XKBOPTIONS=` in `vconsole.conf`: inert copy localed writes
  despite `--no-convert`; only `KEYMAP` applies.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| `grp:alt_shift_toggle` | `Mod+Space` is the DMS launcher (`niri/dms/binds.kdl`) | `win_space_toggle` |
| One `localectl` call for Xorg/Xwayland/sddm | all three read `/etc/X11/xorg.conf.d/00-keyboard.conf`; sddm is fallback-only | three steps |
| Own map under `/usr/local`: `include` stock `us.map.gz`, keycodes 58/29 swapped | survives `pacman -Syu` of `kbd` (dep of `systemd`, not a feature) | patching `us.map.gz` |

## Verify

```sh
localectl status                 # X11 Layout/Options as in the header
grep KEYMAP= /etc/vconsole.conf  # the map path below, nothing else
loadkeys --mktable /usr/local/share/kbd/keymaps/us-swapcaps.map >/dev/null; echo $?  # 0, applies nothing
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| One surface moved, other did not | three copies; `run_onchange` fires on own text only | `grep -n xkb ~/.config/niri/config.kdl`, `grep -n layout ~/.config/driftwm/config.toml`, `localectl` |
| TTY Caps stays Caps | map did not compile, apply said so on stderr | `loadkeys --mktable` on it |
| `VC Keymap: (unset)` | not a fault: `localectl` prints registry names, not paths | read `/etc/vconsole.conf` |

## See also

Script comments wrong, left as is: `ABSOLUTE path` blames how `loadkeys` is
invoked (2026-07-31: both forms fail alike); `--no-convert` names
`/usr/lib/systemd/kbd-model-map`, absent here.
