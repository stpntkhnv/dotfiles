---
covers:
  features: []
  paths:
    - home/dot_config/ghostty/config
    - home/dot_config/ghostty/themes/create_dankcolors
    - home/dot_config/alacritty/alacritty.toml
---

# Terminal

## What it does

Ghostty, host only, package in feature `desktop` (`always: true`), spawned by
`Mod+T` (`niri/dms/binds.kdl`). Colours come from matugen. Alacritty is a
config-only fallback: nothing launches it, no feature installs it.

## Files

| Path | Role |
|---|---|
| `home/dot_config/ghostty/config` | the config; comments give why |
| `home/dot_config/ghostty/themes/create_dankcolors` | placeholder theme, written once |
| `home/dot_config/alacritty/alacritty.toml` | one bind: `Shift+Enter` -> `\r` (ghostty: `text:\n`) |

## How it works

- `gtk-single-instance = false`: one process per window. GTK's default folds
  new windows into the running process when launched outside a CLI (`.desktop`,
  compositor bind); herdr needs it ([multiplexer.md](multiplexer.md)).
  Deliberate opt-out, not a bug workaround - that default is
  [documented and idiomatic upstream](https://ghostty.org/docs/help/gtk-single-instance).
  "One busy window starves the other four": plausible, never measured here.
- DMS reruns matugen per theme change (`matugenTemplate*` in its
  `settings.json`), overwriting `~/.config/ghostty/themes/dankcolors`
  ([desktop.md](desktop.md)). `theme = dankcolors` resolves at startup, so it
  must exist before DMS first runs.
- The generated `~/.config/alacritty/dank-theme.toml` is never read -
  `alacritty.toml` has no `import`. Unintended gap. It needs no `create_`
  twin: naming no theme, it cannot fail on a missing one.
- `ctrl+shift+KeyC`/`KeyV` bind physical key codes: the default matches the
  character "v", which the ru layout never types ([keyboard.md](keyboard.md)).

## Constraints

- `create_dankcolors` keeps its `create_` prefix and stays comment-only:
  chezmoi writes it only when absent, so it and matugen touch that path once
  each. Plain managed it would be rewritten every `apply`, fighting matugen.

## Verify

```sh
ghostty +show-config --changes-only | grep -E 'gtk-single-instance|^theme'
# both present; gone/true => GTK default is back
head -3 ~/.config/ghostty/themes/dankcolors
# hex => matugen owns it; comments => DMS never ran
grep -i 'ghostty\|alacritty' home/.chezmoiignore  # empty: unconditional
```

## See also

[desktop.md](desktop.md), [multiplexer.md](multiplexer.md),
[keyboard.md](keyboard.md), [workarounds.md](workarounds.md).
