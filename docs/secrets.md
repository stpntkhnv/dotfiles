---
covers:
  features: [keepassxc]
  paths:
    - home/.chezmoiscripts/run_onchange_after_82-ssh-key.sh.tmpl
    - home/dot_local/bin/executable_ssh-restore.tmpl
    - home/.chezmoiscripts/run_onchange_after_83-origin-ssh.sh.tmpl
---

# Secrets: KeePassXC vault and SSH keys

## What it does

One local `.kdbx` vault, `~/Documents/Passwords/personal.kdbx`, holds passwords,
TOTP, passkeys, org PATs and the master copy of every SSH private key. Feature
`keepassxc`: `scope: host`, `needs: [syncthing]`, `pacman: [keepassxc]`.

**Agents get no secrets at all** — no password, no PAT, host or container. The
Bitwarden scheme (`rbw`, `bws`, the `pat` wrapper) was deleted whole on
2026-08-01 (`6804f04`), not narrowed. PATs are copied by hand from the vault
GUI; a terminal wrapper is deliberately absent ([agents.md](agents.md)).

## Files

| Path | Role |
|---|---|
| `…82-ssh-key.sh.tmpl` | host: generate missing keys; container: `ssh-restore` reminder only |
| `…executable_ssh-restore.tmpl` | `~/.local/bin/ssh-restore`; `.chezmoiignore` gates it on `.env == "host"` |
| `…83-origin-ssh.sh.tmpl` | source dir `origin` → `git@github.com:stpntkhnv/dotfiles.git` |
| `~/.ssh/id_*`, `~/homes/<ctx>/.ssh/id_*` | runtime: host pair, per-context pairs |
| `~/Documents/Passwords/personal.kdbx`, `~/.mozilla/native-messaging-hosts/*.json` | runtime, **not chezmoi**: vault by hand, manifest by KeePassXC |

## How it works

- Vault path is fixed by sync: `Documents/Passwords` is the `passwords`
  Syncthing folder (`sendreceive`, `staggered`, desktop/laptop/phone).
- Manual steps, prompted by `run_after_zz-next-steps.sh.tmpl`: create the vault
  (Database > New); Browser Integration on, tick **both** Firefox (covers Zen)
  and Chromium, Connect in each; phone: KeePassDX plus folder `passwords`.
- Eight keys, distinct fingerprints: a pair per context (`digi3`, `stellium`,
  `personal`) plus the host's; one key at two employers links them.
- Script 82 generates each missing key independently, `-N ""`, comment
  `{{ .git_email }}`; if either is generated it prints both `.pub` files.
- Entry names are a **contract**, matched literally: `SSH <target> github
  (ed25519)` with attachment `id_ed25519`, `SSH <target> azure (rsa)` with
  `id_rsa`; `<target>` is a context name or `host`. Public parts are derived by
  `ssh-keygen -y`, not stored.
- `ssh-restore [-f] <target>` stages into a temp dir with 600/644, then `mv`s
  the set into `~/homes/<ctx>/.ssh`, or `~/.ssh` for `host`, the reinstall path
  (below; [install.md](install.md) covers the install around it).

### Reinstall

The vault must arrive before `ssh-restore` can work, and Syncthing is not paired
yet at that point:

```sh
scp <machine>:Documents/Passwords/personal.kdbx ~/Documents/Passwords/
cp /run/media/$USER/<stick>/personal.kdbx ~/Documents/Passwords/  # or removable media
ssh-restore -f host    # -f overwrites the fresh keys 82 just generated
ssh-restore digi3      # repeat per context listed in NEXT STEPS
ssh-keygen -lf ~/.ssh/id_ed25519.pub   # fingerprint must match GitHub >
                       # Settings > SSH and GPG keys, printed under each key
chezmoi apply          # NEXT STEPS re-reads live state, shows what is left
```

If the vault exists nowhere else, the old keys are unrecoverable — register
fresh ones from the NEXT STEPS prompts.

## Constraints

- `host` is a reserved `ssh-restore` target: a context of that name fails
  template render (`fail` guard).
- 83 runs after 82, so `origin` flips only once a key exists; it touches
  `{{ .chezmoi.sourceDir }}` alone, no-ops on absent or correct URL.
- `ssh-restore` refuses without `-f` if a target file exists, and refuses in a
  container (`/run/host`); both checks precede the password prompt.
- A `.kdbx` conflict copy is binary: Database > Merge from database, then delete
  it; `kb-curate` is for text notes only.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| Local `.kdbx` + Syncthing | No server, account, or per-rebuild device registration | Bitwarden cloud, `rbw`/`bws`/`pat`, removed 2026-08-01 |
| Private keys in the vault | A rebuild stops forcing public-key re-registration | Trade: masters on three devices |
| Restore is manual | `apply` must not prompt for a password | — |
| RSA-4096 for Azure DevOps | Only RSA works over SSH there (MS docs checked 2026-07-31, `ms.date: 2026-06-17`); 4096 over the documented 3072 | ed25519 |

## Verify

```sh
pacman -Q keepassxc openssh   # keepassxc 2.7.12-3, openssh 10.4p1-3 (2026-08-03)
git -C "$(chezmoi source-path)" remote -v   # git@github.com:stpntkhnv/dotfiles.git
keepassxc-cli show --show-attachments ~/Documents/Passwords/personal.kdbx "SSH host github (ed25519)"
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `Permission denied (publickey)` | Public part not registered | `id_ed25519.pub` at `github.com/settings/keys`, `id_rsa.pub` in Azure DevOps user settings; after a reinstall, `ssh-restore -f host` first |
| No keys after a container rebuild | By design, 82 never generates there | `ssh-restore <ctx>` on the host |
| `export failed for entry 'SSH …'` | Name mismatch or wrong password | Recheck the contract; target untouched |
| `origin` still HTTPS | 83 is `run_onchange` with unchanging text; a late key does not re-trigger it | `git remote set-url origin` by hand |

## See also

- [agents.md](agents.md) — the agent/secret boundary.
- [sync.md](sync.md) — folder `passwords`, phone.
- [isolation-browser.md](isolation-browser.md) — the extension, by policy.
- [workarounds.md](workarounds.md) — the Azure DevOps RSA row.
