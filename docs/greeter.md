---
covers:
  features: [greeter]
  paths:
    - home/.chezmoiscripts/run_after_45-greeter.sh.tmpl
---

# Login screen: greetd + DMS greeter

## What it does

`greetd` runs the DMS greeter (`dms-greeter` -> temporary niri -> the session's
quickshell config) instead of `sddm`. Host only, feature `greeter`
(`default: true`); `sddm` stays installed via `desktop` as the fallback.

## Files

| Path | Role |
|---|---|
| `home/.chezmoiscripts/run_after_45-greeter.sh.tmpl` | the switch and its rescue trap |
| `home/.chezmoidata.yaml`, `- key: greeter` | `greetd` + AUR `greetd-dms-greeter-git`; failed build kills the apply |
| runtime: `/etc/greetd/{config.toml,niri/*.kdl}`, `/var/cache/dms-greeter` (`0750 greeter:greeter`), `~/.cache/dms-greeter-sync.stamp` | from `dms greeter enable`/`sync` |

## How it works

- `run_after`, not `run_onchange`: theme changes never touch the script's own
  text, so onchange would not re-run. 45 is after all config files, so `sync`
  reads live ones.
- `trap 'check_invariant; exit 0' EXIT` armed before the first fallible
  command; `check_invariant` opens with `set +e`, else a failing line inside
  aborts the trap before `exit 0`.
- `greetd_ok` = unit literally `enabled` + `dms-greeter` on PATH + config names
  it (or is unreadable) + cache dir exists (wrapper exits 1 without it).
- Both on -> disable `sddm`; neither -> disable `greetd` **first** (both claim
  the `display-manager.service` alias), then enable `sddm`.

### Why no layout override

- Upstream sanctions the very file this repo refuses to write — dank-greeter
  `README.md`, `Configuration` > `Compositor`: "`dms-greeter sync` writes the
  generated greeter config to `/etc/greetd/niri/config.kdl`. Add local manual
  tweaks in `/etc/greetd/niri_overrides.kdl`".
- The wrapper appends `include "$override_file"` *after* `config.kdl`, which
  already ends with `include ".../dms.kdl"`: the manual `input` block lands
  second and `niri validate` passes.
- **Proven:** niri `include` is positional, and pointer sections (touchpad,
  mouse, trackpoint) are replaced by the later declaration, not merged ([niri
  wiki, Configuration:
  Include](https://github.com/niri-wm/niri/wiki/Configuration:-Include)).
  **Unproven:** that an override omitting `numlock` drops it — a guess, never
  demonstrated; no ticket in `niri-wm/niri` or `AvengeMedia/dank-greeter`
  (searched 2026-07-31).

## Constraints

- Script 45 may never fail the apply: a live session is on screen, so a
  half-switched login screen is a message, not a failure.
- Untick the feature and 45 renders to `exit 0`, trap included — hence
  30-system seeds `sddm` only behind `systemctl is-enabled --quiet
  display-manager.service ||`; unconditional it fails under `set -e` once
  `greetd` owns the alias.
- `greeter` group membership lands only at next login, so right after a switch
  `sync_needed` cannot stat the cache and misses an emptied one.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| sddm disabled, not removed | rescue path; `dms greeter uninstall` restores it | uninstalling it |
| Layout verified, not written | `sync` copies the layout into `dms.kdl` already, and a later override replaces pointer settings (see above); 24e19ad added the file, c0e2d40 removed it | writing `niri_overrides.kdl`, sanctioned by upstream |
| `DMS_PRIVESC=sudo` on both `dms` calls | `privesc.PromptCLI` checks only `$DMS_PRIVESC` and `stdinIsTTY`, then blocks in `ReadString`; `-y` misses it | `-y` alone |

## Verify

Read-only, measured 2026-07-31.

```sh
systemctl is-enabled greetd.service sddm.service  # enabled / disabled
readlink -e /etc/systemd/system/display-manager.service  # greetd.service
grep -E '^\s*command' /etc/greetd/config.toml  # /usr/bin/dms-greeter
grep -rl xkb /etc/greetd/niri  # /etc/greetd/niri/dms.kdl
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `!! no usable display manager is enabled` | a `greetd_ok` condition failed | check AUR build, `command` line, cache dir |
| `!! could not enable sddm either` | neither unit enabled | TTY login (Ctrl+Alt+F2); no automatic path |
| apply hangs at 45 | `DMS_PRIVESC` lost; `dms` waits on `[1] sudo [2] run0` | Ctrl+C, restore it |
| No numlock, or stale theme | never reached the greeter | `dms greeter sync`; or drop the stamp |

## See also

[desktop.md](desktop.md), [keyboard.md](keyboard.md),
[workarounds.md](workarounds.md),
[dank-greeter](https://github.com/AvengeMedia/dank-greeter).
