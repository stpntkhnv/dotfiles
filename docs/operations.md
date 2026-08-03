---
covers:
  features: []
  paths:
    - home/.chezmoiscripts/run_after_zz-next-steps.sh.tmpl
---

# Operations

Runbook: manual steps, per-subsystem checks, checker blind spots.

## Manual steps

`home/.chezmoiscripts/run_after_zz-next-steps.sh.tmpl` prints `NEXT STEPS` on
every apply (no `onchange_`: it reads live state), silent when nothing is
pending. These need a human: an interactive login, the KeePassXC master
password, a provider-supplied file (Ziti). It only reads, bar an `xdg-mime
default` re-run when the https handler drifts off Junction.

Logins: `claude` then "Log in"; `codex login`; `gh auth login`; `az login`;
`sudo tailscale up`.

| Line | Fix |
|---|---|
| GitHub key (host) | `cat ~/.ssh/id_ed25519.pub` -> github.com/settings/keys; after a reinstall, `ssh-restore -f host` |
| SSH keys (container) | on the host: `ssh-restore <context>` |
| claudefiles setup | `~/.local/share/claudefiles/setup.sh` (interactive, apply skips it) |
| Ziti identity | `sudo cp <id>.json /opt/openziti/etc/identities/`, `sudo systemctl start ziti-edge-tunnel` |
| Handy model | `handy`, Settings -> Model -> Whisper Large v3 |
| Handy first run | `handy`, then apply again |
| KeePassXC vault | `keepassxc`: new DB at `~/Documents/Passwords/personal.kdbx`; Browser Integration on, tick Firefox (covers Zen) AND Chromium, Connect in each; phone: KeePassDX |
| Bitwarden leftovers | `sudo pacman -Rns bitwarden rbw bws-bin; rm -rf ~/.config/{rbw,bws}`; online account LAST |
| dev cert (in box) | `dotnet dev-certs https --trust`, then a NEW shell |
| `docker` group (host) | log out and back in |
| podman socket (in box) | `systemctl --user enable --now podman.socket`, in the box with `nested-podman`, else on the host |
| Zen first run | `zen-browser` once, then apply |
| Zen extension dead | `about:policies`, `about:addons`; apply rebuilds policy and XPI |
| Junction missing | `sudo pacman -S junction`, then apply |
| ST: device map | fill `~/.config/syncthing-devices.yaml` from the printed skeleton; the name must be `desktop`/`laptop`/`phone`, else no folders; repeat everywhere |
| ST: no static address | add `tcp://<name>.<tailnet>.ts.net:22000` beside `dynamic` |
| ST: peer unknown or unseen | apply there, copy its ID; pairing is mutual |
| ST: ufw port closed | `sudo ufw allow 22000/tcp` (+udp, +`21027/udp`); `30-system` adds these once |
| ST: conflict file | `.kdbx`: KeePassXC Database > Merge, delete the copy; else kb-curate |
| ST: vault path | fix `kb.vault_path` in `~/.config/claudefiles/secrets.json`, rerun `setup.sh` |
| Proxy `<ctx>` socket | `distrobox enter <ctx> -- true`, check `wsproxy-bridge.service` |

The rest just need `chezmoi apply`: Zen prefs (Zen closed), context-proxy XPI,
Syncthing config and folders, go-yq. The GitHub check is the only network call
(`ssh -T`, 4 s): offline it shows spuriously.

## Diagnosis index

| Doc | Check |
|---|---|
| [how-it-works](how-it-works.md) | `chezmoi doctor` |
| [install](install.md) | `which chezmoi; pacman -Q chezmoi` |
| [isolation](isolation.md) | `curl -sx socks5h://127.0.0.1:11081 ifconfig.me` |
| [containers](containers.md) | `distrobox list` |
| [isolation-network](isolation-network.md) | `ss -ltn \| grep :1108` |
| [isolation-browser](isolation-browser.md) | `jq -r '.addons[]\|select(.active).id' ~/.config/zen/*/extensions.json` |
| [isolation-links](isolation-links.md) | `xdg-mime query default x-scheme-handler/https` |
| [killswitch](killswitch.md) | in box: `sudo nft list table inet killswitch` |
| [nested-podman](nested-podman.md) | in box: `systemctl --user is-active podman.socket` |
| [base](base.md) | `chezmoi execute-template < home/dot_bashrc.tmpl` |
| [desktop](desktop.md) | `niri validate -c ~/.config/niri/config.kdl` |
| [greeter](greeter.md) | `systemctl is-enabled greetd sddm` |
| [terminal](terminal.md) | `ghostty +show-config --changes-only` |
| [keyboard](keyboard.md) | `localectl status` |
| [multiplexer](multiplexer.md) | `herdr workspace list` |
| [browsers](browsers.md) | `systemctl --user show browser.slice -p MemoryHigh` |
| [voice](voice.md) | `pgrep -a handy` |
| [sync](sync.md) | `systemctl --user is-active syncthing` |
| [network](network.md) | `tailscale status; sudo ufw status` |
| [secrets](secrets.md) | `ssh -T git@github.com` |
| [dev-tools](dev-tools.md) | `code --list-extensions; id -nG` |
| [agents](agents.md) | `git -C ~/.local/share/claudefiles rev-parse HEAD` |
| [hardware](hardware.md) | `zramctl; bluetoothctl list` |

## Doc checker

`tools/gen-catalog.sh --check` reads the repo, not the machine; no part of
`chezmoi apply`. Exit 0 and an empty report mean every feature and every file
under `home/` (plus `install.sh`) is claimed by a `covers` header and every
internal link resolves. Findings name themselves (`UNCOVERED-FEATURE`,
`UNCOVERED-FILE`, `EMPTY-PATTERN`, `HEADER-ERROR`, `BROKEN-LINK`,
`BROKEN-ANCHOR`, ...); external targets are skipped and meaning is never
checked. Summary always on stderr, even when clean: `features with no doc:`,
`files with no doc:`, `other findings:`. Without `--check` it also rewrites
`docs/catalog.md`, never hand-edited (rule 4).

### Three blind spots

- **Plain text is invisible.** `broken_links()` takes targets only from
  `\]\([^)]*\)`, so "see `docs/sync.md`" is neither a `BROKEN-LINK` nor a
  link; a stale anchor already escaped that way.
- **Sources are top-level `docs/*.md` only** (`doc_files()`:
  `find docs -maxdepth 1`, minus `catalog.md`); root `README.md`,
  `docs/issues/*.md`, `home/**`, `tools/**` never are, so a rename breaking a
  `README.md` link is never reported.
- **`covered_universe()` is `git ls-files home/ install.sh`.** A file under
  `home/` never `git add`ed is never `UNCOVERED-FILE`, though chezmoi applies
  it from the working tree (`doc_files()` uses `find`, for untracked
  fixtures). Mirrored: `EMPTY-PATTERN` uses `git ls-files` too, so a
  `covers.paths` entry naming a not-yet-added file is a false alarm.

## Verify

```sh
tools/gen-catalog.sh --check      # empty report, exit 0
chezmoi diff; chezmoi status      # pending changes
chezmoi data | jq '.enabled'      # features here
chezmoi source-path               # source dir in use
chezmoi execute-template < home/.chezmoiignore   # paths kept out of ~
chezmoi execute-template < home/.chezmoiscripts/*20-packages*
chezmoi apply --refresh-externals # force the claudefiles pull
```

## See also

[README.md](README.md), [workarounds.md](workarounds.md), [issues/](issues/).
