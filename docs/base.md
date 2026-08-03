---
covers:
  features: [core, shell, host-base]
  paths:
    - home/dot_bashrc.tmpl
    - home/dot_bash_profile
    - home/dot_profile
    - home/dot_gitconfig.tmpl
    - home/dot_config/starship.toml.tmpl
    - home/.chezmoitemplates/context-badge
---

# Base layer: core, shell, host-base

## What it does

`core` (21 pkgs) and `shell` (9) are `scope: both`, `host-base` (12) is
`scope: host`, all `always: true`. Plus the bash dotfiles.

## Files

| Path | Role |
|---|---|
| `home/dot_bashrc.tmpl` | PATH, `PS1`, guarded tools |
| `home/dot_bash_profile` | Sources `.bashrc` |
| `home/dot_profile` | Appends `~/.local/bin` |
| `home/dot_gitconfig.tmpl` | name/email, credential cache |
| `home/dot_config/starship.toml.tmpl` | Prompt, Latte |
| `home/.chezmoitemplates/context-badge` | Emits `name color fg` |

## How it works

PATH is set three times: no single file covers every shell entry path.
Bash login reads exactly one of `.bash_profile`/`.bash_login`/`.profile`, so
`.profile` never runs for bash login and never sources `.bashrc`. `.bashrc`
**prepends** `~/.npm-global/bin:~/.local/bin:~/.dotnet/tools`; `.profile`
**appends** `~/.local/bin`. `[[ $- != *i* ]] && return` precedes the export,
so `bash -c` gets none of it. A bootstrap `~/.local/bin/chezmoi` thus outranks
the pacman `chezmoi` from `host-base`, against that package's catalog comment
([install.md](install.md)).

The same `.bashrc` ships to host and every container, so tool lines are
`command -v`-guarded (starship/zoxide/fzf as `&&`, eza/bat as `if`).
Trailing `FZF_DEFAULT_OPTS` is not - harmless (env var, not a call), but its
comment's "Each line is guarded" overstates. Other blocks belong to
[multiplexer.md](multiplexer.md), [agents.md](agents.md),
[nested-podman.md](nested-podman.md), [dev-tools.md](dev-tools.md).

Badge colour: `host` -> `sky`; a context name -> its `context_palette` colour
in Latte names (`purple`->`mauve`, `orange`->`peach`); anything else ->
`unknown` on `maroon`: a visible broken state, not a failed apply.

## Constraints

- `host-base` must land before `run_onchange_before_30-system.sh.tmpl` calls
  `enable_unit` on `NetworkManager.service`, `bluetooth.service`, `ufw.service`
  (marked `# host-base`); `set -e` kills the script.
- `core` carries `base-devel` for `makepkg`; `20-packages` still re-runs
  `pacman -S --needed base-devel git` before building yay instead of trusting
  `core`. `curl` is deliberately not in `core` - it is `syncthing`'s.
- context-badge tests `[ -r /run/.containerenv ]`, not `-f`: `.` is a special
  builtin whose failure kills the non-interactive shell even under
  `2>/dev/null`, and `-f` misses existing-but-unreadable. Its `name=;` reset
  keeps chezmoi's own exported `name` out of the fallback.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| `host-base` is `scope: host` | Firewall, NM, Bluetooth, browser-proxy host half are meaningless in a container | Fold into `core` |

## Verify

```sh
tools/gen-catalog.sh --check   # no UNCOVERED-FEATURE lines
chezmoi execute-template < home/dot_bashrc.tmpl   # guard, then PATH
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| Icons/glyphs are empty boxes | No Nerd Font - it is `desktop`'s | [desktop.md](desktop.md) |
| git re-asks for the token | `credential.helper=cache` defaults to 900 s, dies with its daemon | Re-enter |

## See also

- [how-it-works.md](how-it-works.md) - `always`/`scope`/`default`.
- [keyboard.md](keyboard.md) - `30-system` and its units.
