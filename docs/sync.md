---
covers:
  features: [syncthing, obsidian]
  paths:
    - home/.chezmoiscripts/run_after_46-syncthing.sh.tmpl
---

# Sync: notes, passwords, phone photos

## What it does

Syncthing mirrors five folders across desktop, laptop and phone; Obsidian edits
two. Features `syncthing`, `obsidian`: host, `default: true`. Discovery: LAN
and [tailnet](network.md).

## Files

| Path | Role |
|---|---|
| `home/.chezmoiscripts/run_after_46-syncthing.sh.tmpl` | reconciles the daemon over REST each apply |
| `home/.chezmoidata.yaml`, `syncthing.folders` | catalogue; ufw 22000 tcp/udp + 21027 udp via `30-system.sh.tmpl` |
| `~/.config/syncthing-devices.yaml` | device map, not in git: `name: {id, addresses}` |

## How it works

| id | path under `$HOME` | devices |
|---|---|---|
| `kb` | `Documents/Notes/kb` | desktop, laptop |
| `personal` | `Documents/Notes/personal` | desktop, laptop, phone |
| `passwords` | `Documents/Passwords` | desktop, laptop, phone |
| `kb-archive` | `Documents/Notes/kb-archive` | desktop, laptop |
| `camera` | `Pictures/Camera` | desktop, phone |

All `sendreceive` but `camera`, an inbox: `receiveonly` keeps host edits from
going back, phone deletions still land. The first three keep staggered versions
(`maxAge "31536000"`, seconds - the `"365"` this field takes means six minutes).
Only ignore: `.obsidian/workspace*.json` on `personal`; that list is ours
wholesale. `passwords` is created here, its `.kdbx` by hand
([secrets.md](secrets.md)). Containers get no daemon: distrobox mounts this home
into them.

Script 46 matches the daemon's `myID` against the map to see which machine it is,
then PATCH/POSTs devices, options and the folders naming it; no match and it just
prints the ID. Options PATCH pins seven keys: local announce on; global
announce, relays, NAT, crash reports, `startBrowser` off; `urAccepted` `-1`
(refusal, not `0` = ask later).

### New machine (mutual)

1. `chezmoi apply` there: it mints the identity, next-steps prints the ID with a
   paste-ready map entry.
2. Add that entry on **every** working machine, `chezmoi apply` there.
3. Copy the whole map back onto the new machine, `chezmoi apply` again.
4. Phone (chezmoi never touches Android): join the tailnet, add a computer by
   device ID, create `personal` and `camera` with those ids typed exactly - a
   typo silently makes a second folder - and set `camera` to Send Only.

## Constraints

- Script 46 must never exit non-zero (`bail` + `exit 0`, `|| true` on all 7
  `$(...)`) or it fails the whole apply.
- Map keys must be catalogue device names (`desktop`, `laptop`, `phone`); an
  invented one parses, matches nothing, gets no folders.
- `addresses` has no default: global discovery is off, so `dynamic` alone is
  LAN-only. Each needs `tcp://<name>.<tailnet>.ts.net:22000`; next-steps flags a
  leftover `<>` placeholder.
- `kb`'s path must equal `kb.vault_path` in `~/.config/claudefiles/secrets.json`
  (another repo); drift is silent, next-steps prints both.
- No `loginctl enable-linger`: on but not logged in does not sync. `jq` comes
  from `host`.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| REST, per object | The daemon rewrites `config.xml` whole on any GUI change | chezmoi-managed file |
| `run_after_` | Re-asserts settings clobbered in the GUI | `run_onchange_`, blind to all but its text |
| Path from `syncthing paths` | 1.27 moved the default to `$XDG_STATE_HOME/syncthing`, older installs keep `~/.config/syncthing`, `--config`/`STCONFDIR` beat both; a wrong guess mints a *second* identity | hardcoded path |
| Identity by `myID` lookup | A name in a file survives a config copy, then takes another machine's folders | name in `chezmoi.toml` |
| Map outside git | Public repo; IDs, addresses, count are free correlation | `.chezmoidata.yaml`, `chezmoi.toml` |

## Verify

```sh
sudo ufw status | grep -E '22000|21027'   # 3 rules
/usr/bin/yq -o=json . ~/.config/syncthing-devices.yaml   # root is an object
CONF="$(syncthing paths | grep -oE '[^[:space:]]*config\.xml' | head -1)"
KEY="$(sed -n 's:.*<apikey>\(.*\)</apikey>.*:\1:p' "$CONF" | head -1)"
curl -s -H "X-API-Key: $KEY" http://127.0.0.1:8384/rest/config/folders | jq -r '.[].id'
# only ids for this machine
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `Disconnected` forever | ufw blocks the ports on one side, silently | `sudo ufw allow` them; `30-system` is `run_onchange_` |
| `this machine is not in ... yet` | ID absent from the map, or a new identity after a reinstall | add the entry everywhere, apply |

## See also

- [workarounds.md](workarounds.md) - the `.obsidian/workspace*.json` ignore with
  its upstream quote (2026-07-31), and `chezmoi#2184`.
- [issues/2026-08-01-container-kb-vault-path.md](issues/2026-08-01-container-kb-vault-path.md)
