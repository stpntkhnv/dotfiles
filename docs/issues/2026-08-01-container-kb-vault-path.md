# Agent knowledge base in containers pointed at a container-local vault

Found and fixed 2026-08-01; closed upstream 2026-08-02. No repo code changed.

**Symptom** claudefiles setup in a container prints the vault path as
`~/Documents/Notes/kb`, which is not the host vault. All three had their own
empty vault at `~/homes/<ctx>/Documents/Notes/kb`, with
`CLAUDE_CODE_REMOTE_MEMORY_DIR` in each of their three profiles pointing there
- outside Syncthing.

**Root cause** Two layers. (1) `kb.vault_path` in `secrets.json` was empty and
the claudefiles default is `$HOME/Documents/Notes/kb` (`lib/kb.sh`,
`kb_vault_path`); in a container `$HOME` is `~/homes/<ctx>`. (2) Behind it: `kb_settings.py` builds permission rules from
the `$HOME` of the process running it, so a host run emitted `Read(~/...)`,
re-expanding against the container `~`; the container `HOME` gives the
absolute `//home/...` form (double slash is rule syntax).

**Fix** Explicit `kb.vault_path` in all three `secrets.json`, then `kb_apply`
rerun for all nine container x profile pairs with the container `HOME`. Closed
in claudefiles 2026-08-02: `kb_vault_path` now fails fast on an empty path in
a container.

**Recheck** `jq -r '.env.CLAUDE_CODE_REMOTE_MEMORY_DIR'
~/homes/*/.claude*/settings.json | sort -u` - one line.
