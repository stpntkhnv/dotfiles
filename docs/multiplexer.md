---
covers:
  features: [herdr, tmux]
  paths:
    - home/dot_local/bin/executable_work.tmpl
    - home/dot_tmux.conf
    - home/dot_bashrc.tmpl
---

# Multiplexer: herdr, tmux, `work`

## What it does

`herdr` (AUR `herdr-bin`, `scope: both`, asked, default true) is the primary
multiplexer and shows per-pane agent state; `tmux` (pacman, same) is the
fallback. Host-only `work` opens one herdr workspace per context, each inside
its distrobox container. No herdr config is deployed; its defaults stand.

## Files

| Path | Role |
|---|---|
| `home/dot_local/bin/executable_work.tmpl` | `~/.local/bin/work`; contexts baked in from `contexts:` |
| `home/dot_tmux.conf` | `~/.tmux.conf`, both envs. Prefix `C-a`, herdr keeps `ctrl+b` |
| `home/dot_bashrc.tmpl` | Aliases `<ctx>`, `-claude` (if `herdr`), `-tmux` (if `tmux`) |

## How it works

`work` per context: `podman container exists` -> `ensure_server` ->
`workspace_for` -> `first_tab_pane` or `workspace create --no-focus` +
`wait_for_idle_shell` -> `enter_context`. Then `workspace focus`, `exec herdr`.

- Not session restore: `session.json` keeps layout and labels, not the command
  a pane ran.
- Labels are not unique, hence `workspace_for`. Its jq uses `first()`, not
  `| head -1`: head closes the pipe, jq dies of SIGPIPE and `pipefail` kills the
  script - exactly when duplicates exist.
- `pane_is_idle_shell` is positive by design ("only its own shell"): "skip if
  podman is there" would type over vim or a build. Its shell-name clause covers
  `exec vim`, which keeps the pid herdr recorded at creation. It is also the
  readiness check - a fresh pane needs ~0.12 s to drop to one process.
- An unsubmitted line reads as an idle prompt, so `enter_context` sends `ctrl+c`
  and sleeps 0.2 s; without it a pending `rm -rf ~/importan` plus a `pane run`
  ran concatenated, as one command (0.7.5).
- `env HERDR_AGENT=claude distrobox enter ...` labels the pane: herdr reads the
  host pane's foreground group (distrobox + podman), while claude runs on its own
  pty inside. `env VAR=` survives `pane run` on 0.7.5; exported inside the
  container it yields `agent=None`. Price: a pane holding just a shell or an
  editor lists as an idle `claude`.

## Constraints

- Container scan before `ensure_server`, else a containerless machine leaves a
  headless server behind a plain failure.
- `--no-workdir` on the three aliases and in `enter_context`: without it the
  shell edits host files (pulled in via `/run/host`) from the container netns.
- `-L <ctx>` on the `-tmux` twin: tmux's socket sits in `/tmp`, shared with
  every container. Neither multiplexer socket is a boundary, the netns is.
- Every `jq` extraction outside an `if` ends in `|| true`, deliberately without
  `2>/dev/null`: under `set -euo pipefail` a jq exit 2 inside a substitution
  kills the loop, so later contexts never open and `exec herdr` never runs.
  `// empty` guards `null`, not invalid JSON.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| tmux kept beside herdr | herdr is 0.x. Unticking drops the alias and `~/.tmux.conf`, not the package | Deleting tmux |
| `HERDR_AGENT` + screen scraping | Live state, one word on entry | `pane.report_agent` from the container: a reported state takes authority and freezes the sidebar, and `release_agent`/`clear_agent_authority` drop the agent instead of handing state back (`agent=None`) |
| `work` gated on the feature **and** `.env == "host"` | `herdr` is `scope: both`, so a feature-only gate ships `work` into containers with no `distrobox enter` | Feature gate only |

## Verify

```sh
type digi3 digi3-claude digi3-tmux   # HERDR_AGENT on the first two, -L on the last
distrobox enter digi3 -- pwd; distrobox enter --no-workdir digi3 -- pwd
                                     # /run/host/... vs ~/homes/digi3
distrobox enter digi3 -- bash -lc 'ls ~/.local/bin/work'   # absent - correct; without
                                     # bash -lc the host shell expands ~ first
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| Hand-started `claude` not in the sidebar | Entry carried no `HERDR_AGENT` | Enter via an alias or `work` |
| Pane closed, claude still burning CPU | Closing kills only host-side `distrobox enter` | `podman top <ctx>`, `podman exec <ctx> kill <pid>` (`-9` for shells) |

## See also

- [isolation.md](isolation.md), [containers.md](containers.md),
  [agents.md](agents.md), [workarounds.md](workarounds.md) - rows for the herdr
  0.7.5 CLI quirks and `--no-workdir`, with rechecks.
- [issues/2026-07-30-herdr-agent-detection-in-containers.md](issues/2026-07-30-herdr-agent-detection-in-containers.md),
  [issues/2026-07-29-work-unguarded-jq.md](issues/2026-07-29-work-unguarded-jq.md),
  `herdr.dev/docs/agents/`, `distrobox.it/usage/distrobox-enter/`.
