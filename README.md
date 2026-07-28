# dotfiles

Arch Linux workstation configuration managed with [chezmoi](https://www.chezmoi.io/).

## One-line install

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/stpntkhnv/dotfiles/main/install.sh)"
```

Installs chezmoi (if missing), clones this repo, shows a feature checklist,
installs what you picked and deploys the configs.

Works the same on a bare host and inside a distrobox container — the
environment is detected automatically.

If the CDN is serving a stale `install.sh`, fetch it through the API instead:

```sh
sh -c "$(curl -fsSL https://api.github.com/repos/stpntkhnv/dotfiles/contents/install.sh -H 'Accept: application/vnd.github.raw')"
```

## How it works

Everything installable is described in one file, `home/.chezmoidata.yaml`.
Each feature declares its own packages and where it applies:

```yaml
- key: neovim
  label: "Neovim + LSP, treesitter"
  scope: both          # both | host | container
  default: true        # pre-selected in the checklist
  pacman: [neovim, tree-sitter-cli]
```

At install time that becomes a checklist (space toggles, Enter confirms), and
the selection is saved to `~/.config/chezmoi/chezmoi.toml` as `data.enabled`.

Everything else keys off that list:

- `.chezmoiscripts/run_onchange_before_20-packages.sh.tmpl` assembles flat
  `pacman` / AUR / `npm` lists from the selected features and installs them.
  There is no longer a script per program.
- `.chezmoiignore` decides which configs to deploy by feature rather than by
  environment: the VS Code config goes wherever VS Code was picked.

A `run_onchange_` hash is computed over the **rendered** text, so changing the
set of features triggers the install by itself — nothing to run by hand.

### Adding a program

Add a block to `home/.chezmoidata.yaml`. Nothing else needs editing. Fields:
`key`, `label`, `scope`, optionally `always` (install without asking),
`default`, `needs` (other features), `pacman`, `aur`, `npm`.

Adding packages to an existing feature takes effect on the next `chezmoi
apply`. A brand new **feature key** does not: `data.enabled` is computed once,
at init, and `apply` never re-renders `.chezmoi.toml.tmpl`. So a fresh
`always: true` feature is missing from `enabled`, and `.chezmoiignore` silently
drops its targets. On an already-configured machine, run init once:

```sh
chezmoi init      # no --prompt: recomputes `always`, keeps the saved answers
```

`--prompt` is a different thing: it re-asks the whole checklist. Use the bare
form unless you actually want to redo the selection.

To preview what would run, without applying:

```sh
chezmoi execute-template < home/.chezmoiscripts/run_onchange_before_20-packages.sh.tmpl
```

### Changing the selection later

```sh
chezmoi init --prompt     # re-asks everything, including the checklist
chezmoi apply
```

### Non-interactive install

Without a TTY chezmoi falls back from the TUI to line-based input: one feature
per line, blank line to finish.

```sh
printf 'Name\nme@example.com\nneovim\nnode\nclaude\n\n' | chezmoi init --apply --no-tty stpntkhnv
```

Two traps worth knowing about:

- `--promptString` / `--promptBool` are keyed by the **prompt text**, not by
  the field name in `[data]`: `--promptString "Git user name=Name"`.
- `--promptMultichoice` in chezmoi 2.71 **does not split its value into a
  list** — whatever separator you use, it arrives as one string. Use the
  line-based input above to select several features.

## Always configured

No questions asked, because without these the machine does not work:

- base utilities and shell tooling (starship, eza, bat, fzf, zoxide, tmux);
- on the host — the niri + DankMaterialShell desktop with fonts, pipewire,
  portals and sddm;
- on the host — distrobox and podman;
- in a container — locale-gen, xauth and the rest of the container-only
  plumbing.

## Terminal

Ghostty, with one non-negotiable setting: `gtk-single-instance = false`.
Ghostty is a GTK application, and when launched through its .desktop file it
would otherwise route every new window into one already-running process —
the classic daemon-terminal behaviour where one window's heavy output makes
the other four sluggish. With the flag off every window is a separate OS
process with its own GPU context; parallel agents in parallel windows do not
share anything.

Colors are not in the repository: DankMaterialShell renders
`~/.config/ghostty/themes/dankcolors` through matugen on every theme change
(`matugenTemplateGhostty` in DMS settings). chezmoi ships that file as a
`create_` placeholder only — an empty theme is valid and merely means default
colors until DMS runs once; managing the real file would have chezmoi and DMS
overwrite each other forever, same story as the niri `dms/` includes.

tmux declares `default-terminal = tmux-256color` plus an `RGB` terminal
feature for `xterm-ghostty`, so truecolor survives inside tmux sessions.

## Keyboard layout

`us,ru`, switched with **Alt+Shift**, Caps Lock and left Control swapped. Not
`Win+Space`, because `Mod+Space` is taken by the DMS spotlight.

Configured on three surfaces at once:

| Where | How |
|---|---|
| niri session | the `xkb` block in `home/dot_config/niri/config.kdl` |
| Xorg / Xwayland / sddm login screen | `localectl --no-convert set-x11-keymap` |
| Console (TTY) | a keymap of its own at `/usr/local/share/kbd/keymaps/us-swapcaps.map` |

The console is handled separately for a reason: a TTY layout is defined by a
keymap file rather than by xkb options, and systemd's conversion table
(`/usr/lib/systemd/kbd-model-map`) contains no entry mentioning `swapcaps` —
without `--no-convert`, localectl would silently settle on plain `us` and
clobber the swap.

Russian is deliberately absent in the TTY: switching language in the console
needs a dedicated map such as `ruwin_ctrl`, whose toggle collides with this
swap. What matters here is having Control under the little finger when
graphics fail to come up.

## Distrobox

```sh
distrobox assemble create --name digi3 --file ~/.config/distrobox/distrobox.ini
```

Always pass `--name`: `distrobox-assemble` treats every INI section as a
container, including `[base]`, and without a name it will create a redundant
`base` container too.

The `archlinux:latest` base image ships with an empty `mirrorlist` and no
`Include` for `[extra]`; the `10-bootstrap-pacman` script fixes both before
the first `pacman -Syu`, so no manual bootstrap is needed.

Set a container up with the same installer:

```sh
distrobox enter <name>
sh -c "$(curl -fsSL https://raw.githubusercontent.com/stpntkhnv/dotfiles/main/install.sh)"
```

After that use the `.bashrc` aliases (`digi3`, `stellium`, `personal`); each
gets its own tmux socket.

### `podman info` fails on overlay

```
Error: configure storage: kernel does not support overlay fs:
'overlay' is not supported over extfs
```

This is not about the filesystem. Upgrading the `linux` package removes the
modules of the running kernel, and `overlay` stops existing until a reboot:

```sh
uname -r          # running kernel
pacman -Q linux   # installed package
grep -c overlay /proc/filesystems
```

Versions disagree and the third line prints `0` -- reboot, nothing else.

## Work context isolation

One browser, on the host. Each of its containers routes its egress back into
the matching distrobox container over SOCKS5 carried on a UNIX socket, so the
traffic still leaves through that context's own netns, resolver and VPN
rather than through the host.

Per context:

```
Zen container "digi3"
  -> SOCKS5 127.0.0.1:11081            (host, wsproxy-digi3.service)
  -> ~/.local/share/wsproxy/digi3/socks.sock
  -> /mnt/sockets/socks.sock           (container, wsproxy-bridge.service)
  -> 127.0.0.1:1080                    (container, wsproxy-socks.service)
  -> digi3's netns / resolver / VPN
```

A UNIX socket rather than a port because it is a filesystem object: it crosses
the network-namespace boundary without weakening it. The host always dials in,
the container never learns a route back. Each container sees only its own
socket directory; a shared one would let any container reach a neighbour's
proxy and leave through the wrong VPN.

The list of contexts and ports is `contexts:` in `home/.chezmoidata.yaml`.
Adding a context means adding one entry there and running `chezmoi apply`.

After changing anything:

```sh
ss -ltnp | grep -E '1108[0-9]'                                   # bridges listen
ls -l ~/.local/share/wsproxy/*/socks.sock                        # containers answer
curl -s --socks5-hostname 127.0.0.1:11081 https://api.ipify.org  # end to end
distrobox enter digi3 -- ls /mnt/sockets                         # only its own socket
```

### Routing test

Existence checks prove the parts are there. They do not prove a tab's traffic
went where it should: a proxy assigned to the wrong container, `proxyDNS` left
off, or a name in `ext+container:` that does not match a container (the
extension then creates it silently, without a proxy) all look fine from
outside. Comparing public IPs does not discriminate either while no context
has a VPN. A container's own loopback does.

```sh
for c in digi3 stellium personal; do
  distrobox enter "$c" -- sh -c "printf 'HTTP/1.0 200 OK\r\nContent-Type: text/plain\r\n\r\n%s\n' \"\$(. /run/.containerenv; echo \$name)\" > /tmp/whoami.http"
  distrobox enter "$c" -- sh -c 'setsid socat TCP-LISTEN:8099,bind=127.0.0.1,fork,reuseaddr SYSTEM:"cat /tmp/whoami.http" >/dev/null 2>&1 &'
done

curl -s --max-time 5 http://127.0.0.1:8099/            # must fail: host has nothing there
for p in 11081 11082 11083; do
  printf '%s -> ' "$p"
  curl -s --socks5-hostname "127.0.0.1:$p" http://127.0.0.1:8099/
done                                                    # must print digi3, stellium, personal
```

Then open `http://127.0.0.1:8099/` from each Zen workspace: the page must name
that workspace's context. From `Scratch` it must not load at all. Clean up:

```sh
for c in digi3 stellium personal; do
  distrobox enter "$c" -- sh -c 'pkill -f "TCP-LISTEN:8099" || true; rm -f /tmp/whoami.http'
done
```

### Configured by hand

Browser profile state has no update-proof file representation, so this part is
manual, once:

1. **Containers.** Multi-Account Containers -> create `digi3`, `stellium`,
   `personal`, `Scratch`. The names must match `contexts:` exactly: `zen-open`
   substitutes them into `ext+container:name=...` verbatim.
2. **Proxy per container.** For each work container: SOCKS5, `127.0.0.1`, the
   port from `contexts:`, **proxyDNS on**. Without it resolution goes to the
   host resolver, internal names do not resolve, and the list of internal hosts
   leaks outward. `Scratch` gets no proxy.
3. **Workspaces.** One per context. `Set Profile` on a workspace picks a
   **container**, not a Firefox profile; real profiles are hidden behind
   `about:profiles`.
4. **Temporary Containers** -> automatic mode.
5. **Open external links in a container** -> enable HMAC signing, which closes
   the case where a page feeds an `ext+container:` link aimed at a container
   other than the current one.
6. **"Always Open in Container" rules** go **only** on domains unique to one
   context. Never on shared ones such as `dev.azure.com`, `portal.azure.com`,
   `teams.microsoft.com` or `login.microsoftonline.com`: a domain rule *pulls*
   a link out of its current container.
7. **Bookmarks** rewritten as `ext+container:name=<Context>&url=<encoded>`. The
   container belongs in the link, not in the ambient context: otherwise a
   bookmark for stellium clicked from the digi3 workspace lands in digi3.
8. **Pinned tabs and Essentials** per workspace, so reaching a frequent
   resource needs neither a typed address nor a bookmark.
9. **Bitwarden**: auto-fill on page load off; URI match detection `Never` for
   the shared Microsoft domains, `Host` for unique ones; one account per
   context.
10. `about:logins` emptied.

Containers not in use get stopped (`distrobox stop <name>`): memory, and fewer
live network stacks at once. The host bridge survives it -- the listener stays
up, only individual connections fail.

One residual hole: typing a URL by hand from the wrong workspace. It only
matters for addresses that name a specific organisation
(`dev.azure.com/<org>`, invite links), and those are never typed -- they arrive
from outside, which is covered above.

## Voice input

The `voice` feature installs [Handy](https://handy.computer), an offline
speech-to-text app.

Handy runs Whisper through whisper.cpp, whose Linux GPU backend is **Vulkan,
not CUDA**. A card only needs its normal driver and Vulkan ICD; the `cuda`
package does nothing for it. `chezmoi init` probes for an NVIDIA card by
reading `/sys/bus/pci` (not `lspci`, which lives in pciutils and may be absent
on a minimal install) and offers to install the driver if it is missing. That
question is asked at init rather than mid-apply because the install needs a
reboot.

Tauri cannot grab global shortcuts on wlroots-style compositors, so niri owns
the keybind and signals the running process instead: **Mod+Shift+D** sends
`SIGUSR2`. That binding and `spawn-at-startup` live in
`home/dot_config/niri/voice.kdl.tmpl`, which `config.kdl` includes
unconditionally and which renders to a comment-only file when the feature is
off.

After installing, launch Handy once and download a model (Settings → Model).
Whisper Large v3 Turbo (~1.6 GB) is the multilingual, GPU-accelerated one.

## niri and DankMaterialShell files

`config.kdl` includes several files from `dms/`. The split is:

- `binds.kdl`, `cursor.kdl` — **ours**, kept in the repository;
- `colors.kdl`, `layout.kdl`, `alttab.kdl`, `outputs.kdl`, `wpblur.kdl` —
  generated by DMS (they carry an "AUTO-GENERATED BY DMS" header). They are
  not in the repository and should not be: DMS rewrites them on every theme
  change, and chezmoi would fight it forever.

The problem was that on a clean machine the generated files do not exist yet,
and niri has no conditional `include`: it failed to find them, bailed out
while parsing and fell back to the default config. The
`run_after_80-niri-dms-placeholders` script creates the missing ones empty —
an empty KDL document is valid as far as niri is concerned, and DMS overwrites
them afterwards. The list is read from `config.kdl` itself, so a new `include`
never requires editing the script.
