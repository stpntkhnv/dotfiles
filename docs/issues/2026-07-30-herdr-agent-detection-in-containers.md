# herdr does not see an agent running inside a container

2026-07-30, `herdr-bin 0.7.5-1`. Fixed; the anomaly below closed wontfix.

**Symptom** claude started by hand after `distrobox enter` is invisible:
`agent explain` -> `agent_not_found`.

**Root cause** herdr identifies the agent from the foreground process group of
the *host* pane, which under `distrobox enter` is `distrobox` + `podman`.
State detection is unrelated to processes - it is screen/OSC rules in
`agent-detection/remote/claude.toml` (2026.07.13.1).

**Fix** `HERDR_AGENT=claude` on the entry command, in `home/dot_bashrc.tmpl`
and `home/dot_local/bin/executable_work.tmpl`. Rejected: `export HERDR_AGENT`
inside the container shell (herdr reads the env of the process it spawned);
`pane.report_agent` over the socket - reachable from a container, but a
reported state takes authority and freezes the sidebar, and neither
`release_agent` nor `clear_agent_authority` hands it back, so it needs claude
hooks per transition per container; `herdr integration install claude` only
hooks `SessionStart`. Unexplained and not chased: one pane stopped accepting
`pane.report_agent` at all, unreproducible on fresh panes.

**Recheck** Enter a context by its alias, then `herdr agent list` - the pane
shows `agent=claude`.

**CLI traps** (0.7.5, independent of the fix) `--help` usage ends
`--state <STATUS> <PANE_ID>` and is wrong: only `<PANE_ID>` first works, as
`herdr.dev/docs/cli-reference/` has it - built-in usage and site disagree.
Colon in an option value breaks parsing; a parse failure is silent with `rc=0`
off a tty. Recheck: `herdr pane report-agent --help`, `<PANE_ID>` still last.
