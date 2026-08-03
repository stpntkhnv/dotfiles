---
covers:
  features: []
  paths:
    - home/.chezmoidata.yaml
    - home/.chezmoi.toml.tmpl
    - home/.chezmoiignore
---

# How chezmoi applies this repo

## What it does

One catalogue, a checklist built from it at `init`, a per-feature deploy gate,
28 numbered scripts.

## Files

|Path|Role|
|---|---|
|`home/.chezmoidata.yaml`|Truth: 38 `features` + `contexts`, `plain_context`, `syncthing`, bookmarks|
|`home/.chezmoi.toml.tmpl`|Rendered at `init` only; writes `data.enabled`, `env`, `nvidia_driver`|
|`home/.chezmoiignore`|Per-feature deploy gate|
|`~/.config/chezmoi/chezmoi.toml`|Runtime, per machine: the answers|

## How it works

### Catalogue

Fields: `key`, `label`, `scope` (`both|host|container`), `always`, `default`,
`needs`, `pacman`, `aur`, `npm`, `dotnet`. `scope` hides a feature in the wrong
environment (`/run/.containerenv` decides). File order = checklist order,
renaming a `key` drops the saved selection. Optional fields only via `hasKey`
(`missingkey=error`). `.chezmoi.toml.tmpl` reads it as text
(`include ... | fromYaml`) - it renders before chezmoi loads `.chezmoidata.*`;
elsewhere it is `.features`.

### Adding or editing a feature

- Package on an existing feature: edit the list; script 20 re-renders, fires.
- New feature: a `- key:` block, doc coverage, `tools/gen-catalog.sh`
  (CLAUDE.md 2, 2a, 4).
- **Trap**: the checklist is built at `init`, never at `apply`. `always: true`
  -> re-run `chezmoi init` without `--prompt`. Anything asked, even
  `default: true`, needs `data.enabled` edited by hand: `promptMultichoiceOnce`
  returns the saved value without diffing fresh `choices`
  ([workarounds.md](workarounds.md)). `--prompt` re-asks from catalogue
  defaults and drops hand-enabled non-`default` features.
- `needs` expands afterwards, three passes, **ignoring `scope`**:
  `rider`->`dotnet`, `keepassxc`->`syncthing`, `claude`/`codex`->`node`.
- 38 features = 8 `always`, 17 `default`, 13 off. `nvidia_driver` is not one:
  probed from `/sys/bus/pci/devices`, asked only if the card lacks it.

### Ordering

`before` -> file deployment -> `after`. Within a stage the sort key is the name
after chezmoi strips `run_`/`once_`/`onchange_`/`before_`/`after_`
(`internal/chezmoi/attr.go`, `parseFileAttr`, v2.71.1): `onchange` decides
whether the body runs, never its position. 40 appears in both stages without
collision; no `during` script here.

|#|Script|Does|Where|
|---|---|---|---|
|b10|bootstrap-pacman|mirrorlist + `[extra]`|cont|
|b15|wsproxy-container|microsocks + socat|cont|
|b20|packages|the one installer, 4 managers|both|
|b30|system|keyboard, zram, firewall|host|
|b32|browser-extensions|extension policies|host|
|b35|nvidia|driver + Vulkan|host|
|b40|voice|Handy setup|host|
|b50|bluetooth|USB autosuspend quirk|host|
|b60|ziti|unit + identity dir|both|
|b70|azure|`azd` installer|both|
|a33|browser-slices|`daemon-reload` on slice edits|host|
|a34|wsproxy-host|socat unit per context|host|
|a35|bridges-up|restarts dead bridges|host|
|a36|nested-podman|subuid/storage for podman|cont|
|a37|container-links|links to host browser|cont|
|a38|linkrouting|Junction `.desktop` per context|host|
|a39|killswitch|nftables default-drop|cont|
|a40|zen-prefs|`user.js` in Zen profile|host|
|a41|zen-context-proxy|SOCKS per container|host|
|a43|zen-session|Zen space per context|host|
|a44|handy-settings|merges Handy settings|host|
|a45|greeter|greetd + DMS login|host|
|a46|syncthing|merges daemon `config.xml`|host|
|a80|niri-dms-placeholders|creates DMS includes|host|
|a81|vscode-extensions|installs `extensions.txt`|both|
|a82|ssh-key|key gen / vault hint|both|
|a83|origin-ssh|repo origin HTTPS -> SSH|both|
|azz|next-steps|manual steps left|both|

### What re-triggers a script

`onchange` hashes the **rendered** text: catalogue edits retrigger, machine
state never does. Anything depending on live state must be `run_after_` (8
today): apps rewriting their own config from their UI (44, 46), the Zen
profile (40, 43), units torn down behind the script's back (35). Script 40 was
`onchange` and never worked: its first run predated the Zen profile, it printed
the skip line, the hash was stored, `user.js` never appeared. Retriggering on
another repo file needs that file in the render: 33 embeds five unit hashes,
81 embeds `extensions.txt` whole ([dev-tools.md](dev-tools.md)).

### `.chezmoiignore`

Gates on features, not environments: the VS Code config lands wherever `vscode`
is on. Env tests only in exceptions - `.local/bin/work`,
`.local/bin/ssh-restore` (`ne .env "host"`), `user.slice.d/**`. `browser.slice`
and `slice-run` go only when no browser feature is left. Scripts are absent by
design: not targets, they self-disable with `exit 0`. Ignoring stops future
deployment only - it removes nothing.

## Constraints

- Keys are string-compared (`has "X" .enabled`); a typo is silent.
- No script may fail the apply (script 46: "NOTHING HERE MAY FAIL THE APPLY");
  under `set -e` a nonzero exit skips the rest of the stage.
- Script 34 exits 1 before writing any unit on duplicate context names or ports
  or a context reusing `plain_context.name`; it and 38 prune stale units and
  `.desktop` entries first, so a rename leaves nothing live.

## Decisions

|Decision|Why|Rejected|
|---|---|---|
|`onchange` hashes the render|a catalogue edit must trigger installs|per-feature scripts|
|Ignore gated by feature|one program is wanted in both environments|host/container split|

Drift: the comment example `enabled=neovim,node,claude` is wrong - comma
separates prompts, `/` separates values.

## Verify

```sh
grep -c '^  - key:' home/.chezmoidata.yaml   # 38
ls home/.chezmoiscripts | wc -l              # 28
ls home/.chezmoiscripts | grep -c onchange   # 20
chezmoi execute-template < home/.chezmoiignore
```

## Failure modes

|Symptom|Cause|Fix|
|---|---|---|
|Config missing though feature on|key mismatch in `.chezmoiignore`|render it against `data.enabled`|

## See also

[install.md](install.md) - install from scratch;
[isolation.md](isolation.md), [sync.md](sync.md) - the non-feature blocks.
