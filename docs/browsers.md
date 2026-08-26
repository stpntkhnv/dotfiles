---
covers:
  features: [firefox, chromium]
  paths:
    - home/dot_config/systemd/user/browser.slice
    - home/dot_config/systemd/user/browser-chromium.slice
    - home/dot_config/systemd/user/browser-firefox.slice
    - home/dot_config/systemd/user/browser-zen.slice
    - home/dot_local/bin/executable_slice-run
    - home/dot_local/share/applications/firefox.desktop.tmpl
    - home/dot_local/share/applications/chromium.desktop.tmpl
    - home/.chezmoiscripts/run_onchange_after_33-browser-slices.sh.tmpl
---

# Browser memory caps

## What it does

Host-only slices cap browser memory; `.desktop` overrides launch via
`slice-run`. `firefox`/`chromium` are separate checklist items, no preselect;
`zen` owns `browser-zen.slice` ([isolation-browser.md](isolation-browser.md)).

## Files

Under `home/`; gating in `.chezmoiignore`.

| Path | Role |
|---|---|
| `dot_config/systemd/user/browser{,-firefox,-chromium,-zen}.slice` | 10G/12G umbrella; firefox/chromium 3G/4G; zen 7G/10G |
| `dot_local/bin/executable_slice-run` | `slice-run <slice> <cmd>...` |
| `dot_local/share/applications/{firefox,chromium}.desktop.tmpl` | shadow system entries; `Exec` = `slice-run <slice> <bin>` |
| `.chezmoiscripts/run_onchange_after_33-browser-slices.sh.tmpl` | `daemon-reload` |

## How it works

- Dash nesting; no `Slice=` key anywhere (2026-07-31).
- Umbrella 8G < children sum 14G on purpose: with all three open the shared
  cap binds first. Zen's is largest - all work contexts in one tree.
- Sizing is measured, not guessed: live Zen sat at 4.51 GiB
  (`memory.current` 4841762816) against its then-5G `MemoryHigh` (2026-07-31).
  Resized 2026-08-26: Zen had outgrown 5G/6G into local `99-local.conf`
  drop-ins (9G/10G zen, 10G/12G umbrella) - measured 8.58 GiB, 30 tabs, 28
  pinned. The repo now carries zen 7G/10G and umbrella 10G/12G; `High=7G` is
  deliberately below the measured footprint so the kernel keeps squeezing cold
  pages into zram, and the drop-ins are retired (removing them is a manual
  step, they were never chezmoi's).
- DMS wraps `.desktop` `Exec` in `systemd-run --user --scope`
  (`DMS_DEFAULT_LAUNCH_PREFIX`, literal in `/usr/bin/dms`, package `dms-shell
  1.5.3-1`, read by `launchDesktopEntry` in `SessionService.qml`, 2026-07-31;
  recheck `strings /usr/bin/dms | grep DMS_DEFAULT_LAUNCH_PREFIX`), so `slice-run`'s
  second `systemd-run` for the same PID needs `--unit="${slice%.slice}-$$"`:
  the auto name `run-p<PID>-i<inv>.scope` repeats and fails
  "Unit ... was already loaded". Wrapper, not a disabled prefix (it scopes
  all panel apps).
- Script 33 hashes the four slices plus `user.slice.d/50-agents-budget.conf`,
  refiring on edits; gate: browser feature or `.env == "host"`.

## Constraints

- `daemon-reload` won't retarget a live scope; restart the browser.
- Only `slice-run` launches are capped; terminal/PWA/etc escape.
- `slice-run` also backs `claude`/`codex` in `.bashrc` (`user-agents.slice`)
  ([agents.md](agents.md)); caps cover the browser cgroup tree only,
  machine-wide is zram + `earlyoom` ([hardware.md](hardware.md)).
- Feature toggles later need `data.enabled` edited
  ([workarounds.md](workarounds.md)).

## Verify

```sh
systemctl --user show browser.slice browser-zen.slice -p MemoryHigh -p MemoryMax
# 6442450944/8589934592, 5368709120/6442450944 (2026-07-31)
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| Edited cap has no effect | live scope keeps old config | reload, restart |
| "Unit ... was already loaded" | bare `systemd-run --scope` in `Exec` | restore `slice-run` in `Exec` |

## See also

- [desktop hang, 2026-07-30](issues/2026-07-30-desktop-hang-out-of-memory.md)
