---
covers:
  features: []
  paths:
    - install.sh
    - home/.chezmoiscripts/run_onchange_before_20-packages.sh.tmpl
---

# Install on a clean machine

## What it does

Bare host or fresh container → configured machine in one command: chezmoi,
three prompts, packages, files.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/stpntkhnv/dotfiles/main/install.sh)"
```

Stale raw-CDN copy → same file via the API:

```sh
sh -c "$(curl -fsSL https://api.github.com/repos/stpntkhnv/dotfiles/contents/install.sh -H 'Accept: application/vnd.github.raw')"
```

## Files

| Path | Role |
|---|---|
| `install.sh` | POSIX sh entry point, 39 lines; needs curl or wget. |
| `home/.chezmoi.toml.tmpl` | The prompts; writes `~/.config/chezmoi/chezmoi.toml` (`data.enabled`). |
| `…10-bootstrap-pacman.sh.tmpl` | Container only: empty mirrorlist, no `[extra]` `Include`. |
| `…20-packages.sh.tmpl` | The installer: pacman, AUR, npm, dotnet. |

## How it works

- No chezmoi in `PATH` → upstream `https://git.io/chezmoi` drops one in
  `~/.local/bin`. `install.sh` never clones: chezmoi resolves
  `user`/`user/repo` and SSH vs HTTPS.
- `.chezmoiroot` beside the script (`script_dir` from `command -v -- "$0"`)
  means a checkout → `chezmoi init --apply "--source=$script_dir"`; under
  `curl | sh` there is no script file → `chezmoi init --apply stpntkhnv`.
- `set +e` there is deliberate: `install.sh` checks `$?` and prints a `chezmoi
  apply` hint (it used to `exec`, dying silently).
- Prompts: `Git user name`, `Git user email`, `What to install`. `env` from
  `stat "/run/.containerenv"` hides host-only features. An unready NVIDIA GPU
  (PCI class `0x030*`, vendor `0x10de`, no `/dev/nvidiactl`) adds a fourth,
  host only: `Install the NVIDIA driver and Vulkan runtime (needs a reboot)`.
- `20-packages` renders flat `pacman/aur/npm/dotnet` lists from enabled
  features; `run_onchange` hashes that text, so a changed set re-triggers it.
  `dotnet tool update -g`, not `install` (fails if installed).

### Non-interactive

No TTY → line input: one answer per line, blank line ends the multichoice (plus
one if the NVIDIA question fires).

```sh
printf 'Name\nme@example.com\nneovim\nnode\nclaude\n\n' | chezmoi init --apply --no-tty stpntkhnv
```

```sh
chezmoi init --apply --promptString 'Git user name=Name' \
  --promptString 'Git user email=me@example.com' \
  --promptMultichoice 'What to install=neovim/node/claude' \
  stpntkhnv
```

- Keys are the prompt **text**, not `[data]` field names; `git_name=…` never
  matches, silently.
- Values split on `/`; commas separate *different* pairs, so `neovim,node` is
  `invalid choice` (`internal/cmd/interactivetemplatefuncs.go`,
  `promptMultichoiceInteractiveTemplateFunc`, v2.71.1).

### Changing a saved choice

- Any feature: edit `data.enabled` in `chezmoi.toml`, then `chezmoi apply`;
  nothing is re-asked.
- `always: true` feature: bare `chezmoi init` (no `--prompt`) recomputes the
  always list, saved answer untouched.
- Reinstall: script 82 makes fresh, unregistered keys; the real ones return
  with `ssh-restore -f host` ([secrets.md](secrets.md)).

## Constraints

- **Never `chezmoi init --prompt` on a configured machine.** It sets
  `forcePromptOnce`: `promptMultichoiceOnceInteractiveTemplateFunc` skips its
  saved-value branch and re-asks pre-ticked from the catalogue's
  `default: true` set (`$defaults` never reads the existing `chezmoi.toml`),
  and `init` rewrites that file whole — a hand-enabled non-default feature
  vanishes. `promptStringOnce` obeys the same flag: name and email go too.
- Nothing removes the bootstrap chezmoi and `~/.local/bin` precedes system
  paths (`home/dot_bashrc.tmpl`), so it shadows the pacman `chezmoi` from
  always-on `host-base`. `which chezmoi` and `pacman -Q chezmoi` both answering
  = the older copy wins.
- `--allow-scripts=@anthropic-ai/claude-code` stays on the npm command line: a
  `before` script runs before `~/.npmrc` exists; a blocked `postinstall` leaves
  `~/.npm-global/bin/claude` dangling.
- `apply` cannot finish the machine; `run_after_zz-next-steps.sh.tmpl` prints
  the rest ([operations.md](operations.md)).

## Verify

```sh
chezmoi execute-template < home/.chezmoiscripts/run_onchange_before_20-packages.sh.tmpl
# "# Selected features: ..." then the real pacman -Syu call; applies nothing
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `Setup did not complete` | a script under `init --apply` failed | fix it, then `chezmoi apply`; answers kept |
| `claude`: "No such file or directory" | dangling symlink: npm ran without `--allow-scripts` | `chezmoi apply` |

## See also

[how-it-works.md](how-it-works.md), [workarounds.md](workarounds.md),
[chezmoi init](https://www.chezmoi.io/reference/commands/init/).
