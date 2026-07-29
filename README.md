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
at init, and `apply` never re-renders `.chezmoi.toml.tmpl`. What fixes that
depends on the kind of feature.

An `always: true` feature needs one bare init, which recomputes the always-set
and leaves the saved checklist answer alone:

```sh
chezmoi init      # no --prompt: recomputes `always`, keeps the saved answers
```

An **asked** feature is not fixed by that. The checklist answer is read with
`promptMultichoiceOnce`, and `Once` means a stored value is returned as-is —
new choices are never mixed in. `--prompt` does re-ask, but it offers the
*catalogue defaults*, not what you picked last time, so accepting them silently
drops every non-default feature you had. It re-asks the git identity too, and
an empty answer stores an empty string.

So for a new asked feature, edit the list by hand:

```sh
$EDITOR ~/.config/chezmoi/chezmoi.toml   # add the key to data.enabled
chezmoi apply
```

To preview what would run, without applying:

```sh
chezmoi execute-template < home/.chezmoiscripts/run_onchange_before_20-packages.sh.tmpl
```

### Changing the selection later

`--prompt` really does re-ask everything, but "re-ask" starts from the
**catalogue defaults** in `home/.chezmoidata.yaml`, not from what this
machine currently has ticked — the same trap as the new asked feature above.
Accepting the pre-ticked checklist silently drops every feature that is not
`default: true`; anything picked by hand has to be re-ticked or it does not
survive the `apply`.

```sh
chezmoi init --prompt     # re-asks everything, pre-ticked with defaults only
chezmoi apply
```

That is still the right tool when the goal is genuinely to redo the whole
selection. To add or drop a single feature without disturbing the rest, skip
`--prompt` and edit `data.enabled` by hand instead, as under [Adding a
program](#adding-a-program).

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

- base utilities and shell tooling (starship, eza, bat, fzf, zoxide);
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

## Multiplexer

Two of them, and that is deliberate. Both are ordinary checklist features, so
a machine can have either or both.

herdr lives on the host, tmux lives in the container. Both stay `scope: both`
in the catalogue, so a machine can install either in either place -- the
division is the default use, not a restriction. herdr has to be outside the
containers, because its job here is to hold one space per context and enter
each container from the host. tmux is the way into a container and the way to
keep a session running there when herdr is not available.

On a machine that already had this repository before this change, neither
key is there: `herdr` and `tmux` are new asked features, and a stored
`data.enabled` never gains a new key by itself (see [Adding a
program](#adding-a-program)). Left alone, the context aliases quietly degrade
to `distrobox enter --no-workdir <name>` with none of the multiplexer twins,
`work` is never deployed, and `~/.tmux.conf` stops being managed -- nothing
errors, so the `apply` looks successful. Add both keys to `data.enabled` by
hand before applying.

[herdr](https://herdr.dev) is the primary one. It is a multiplexer in the tmux
sense -- panes, tabs, detach and reattach -- that additionally knows the thing
in a pane is a coding agent and shows its state in a sidebar. It is also a 0.x
project moving quickly, which is why tmux is not deleted: the context aliases
keep a `-tmux` twin, so falling back costs nothing.

No herdr config is shipped. The defaults are good, including the `ctrl+b`
prefix, which differs from this repository's tmux (`C-a`). tmux declares
`default-terminal = tmux-256color` plus an `RGB` terminal feature for
`xterm-ghostty`, so truecolor survives inside tmux sessions; herdr needs no
equivalent.

### `work`

```sh
work
```

One command for the whole desk. It starts a headless herdr server if none is
running, gives every context in `contexts:` a space of its own, types
`distrobox enter --no-workdir <context>` into each space's root pane, and then
attaches the TUI. Detach with `ctrl+b`, `q`: the server is headless and
outlives the client, so the panes carry on.

Why a script and not herdr's own session restore: herdr remembers the layout
and the space names, but not the command a pane was running. A restored space
comes back holding a plain host shell, and the entry would have to be typed
again every morning.

The context list is baked in when the template renders, out of `contexts:` in
`home/.chezmoidata.yaml` -- the same list that generates the aliases, the proxy
bridges and the browser containers. A context whose container does not exist is
skipped, with the `distrobox assemble create` line printed to fix it; if not
one context is available, `work` says so and exits before any server is
started.

Running `work` a second time is safe. Spaces are looked up by label instead of
being created again, and a pane is written to only when its single foreground
process is that pane's own shell, by pid and by name. A pane holding an editor,
a build, or a container that was entered already is left alone.

That check has one hole nothing can close: a line you have typed and never
submitted looks exactly like an idle prompt. So `work` sends `ctrl+c` first and
types its own command after. Without that the two arrive at the shell as one
line: on 0.7.5 a pending `echo DANGEROUS-PARTIAL` followed by `echo
SAFE-MARKER` ran as `echo DANGEROUS-PARTIALecho SAFE-MARKER`. The pending line
is discarded, and it is the one thing `work` destroys.

`work` is deployed on the host and only when `herdr` is ticked. herdr itself is
`scope: both`, so gating on the feature alone would put `work` inside every
container, where `distrobox enter` does not exist.

### What you type inside a pane

Three aliases per context, generated from `contexts:`, so a new work context
brings its own shortcuts along with everything else. They are typed inside a
herdr pane; none of them starts herdr:

```sh
digi3         # distrobox enter --no-workdir digi3
digi3-claude  # HERDR_AGENT=claude distrobox enter --no-workdir digi3 -- claude
digi3-tmux    # distrobox enter --no-workdir digi3 -- tmux -L digi3 new-session -A -s work
```

The twins are conditional: `-claude` renders only while `herdr` is ticked,
`-tmux` only while `tmux` is.

`--no-workdir` is on every one of them, and it is not cosmetic. Without it
distrobox carries the host's working directory into the container through
`/run/host`, so the shell sits in the container's network namespace while
working on the host's files -- the worst of both. Measured from `~`:

```sh
distrobox enter digi3 -- pwd               # /run/host/home/stsiapan
distrobox enter --no-workdir digi3 -- pwd  # /home/stsiapan/homes/digi3
```

The tmux twin carried that fault already, so the flag is a fix and not only a
rule for the new commands.

`HERDR_AGENT=claude` is what puts the agent in herdr's sidebar. herdr
identifies an agent by the foreground process group, and through `distrobox
enter` that group is `distrobox` and `podman`, never `claude`: without the hint
the pane is in no agent list at all and the sidebar stays empty, which is the
whole reason herdr is here. It goes on the command and is never exported. A
global `HERDR_AGENT` would label every pane as that agent.

`-L digi3` in the tmux twin is a different kind of flag and must not be
dropped. tmux keeps its server socket in `/tmp`, which distrobox shares with
every container, so `-L <name>` is what stops three contexts from sharing one
server.

### Two faults with no fix

**A closed pane does not kill the agent.** Closing a herdr pane, or the space
holding it, ends the `distrobox enter` on the host and nothing else. What was
running inside the container carries on, orphaned, with no pane left to show
it. It is visible only through `podman top`, and it has to be killed from there
by pid:

```sh
podman top digi3 -eo pid,ppid,user,tty,args
podman exec digi3 kill <pid>
```

Measured: `sleep 600` started through a pane was still listed by `podman top
digi3` after the space holding it had been closed, and `kill` cleared it. An
interactive shell does not go as quietly: a `bash -l` left the same way
ignored `kill` and stayed listed until `kill -9 <pid>`.

**A container can drive the host's herdr.** distrobox mounts the whole host
root into every container as `/run/host`, and the host home at its own path
besides, so the herdr API socket is reachable from inside a container as an
ordinary path:

```sh
distrobox enter --no-workdir digi3 -- \
  env HERDR_SOCKET_PATH=/run/host/home/stsiapan/.config/herdr/herdr.sock \
  herdr workspace list
```

It answers, and it is not read-only: a space created this way from inside
`digi3` ran `readlink /proc/self/ns/net` and printed the host's namespace, not
the container's. This cannot be closed while distrobox mounts the host root,
and it is consistent with what
[BROWSER-ISOLATION.md](BROWSER-ISOLATION.md) already concedes: the threat model
is an employer reading their own logs, not hostile code inside a container.
What separates the contexts is the network namespace; a multiplexer socket,
herdr's or tmux's, separates nothing.

### Two things that are not what they look like

- **Unticking `tmux` removes the `-tmux` twin, not the package.** The package
  installer only ever installs, and `chezmoi apply` does not delete a file
  that has become ignored: the binary stays, and `~/.tmux.conf` stays where it
  was and simply stops being managed. What does go is `digi3-tmux` itself --
  `dot_bashrc.tmpl` renders the twin only while `tmux` is ticked, so the
  fallback this section advertises above stops existing as an alias. Falling
  back then means typing `tmux -L digi3 new-session -A -s work` by hand, or
  ticking `tmux` again. Removing tmux for real is still `pacman -Rns tmux` by
  hand.
- **The DankMaterialShell session panel only speaks tmux and zellij.** It
  probes for the binary rather than reading the feature list, so it keeps
  listing tmux sessions regardless of the checklist, and it will never see a
  herdr session. `muxType` in its settings stays `tmux`.

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

After that use `work`, which opens one herdr space per context, or the
`.bashrc` aliases (`digi3`, `stellium`, `personal`), which open a shell in that
context. See [Multiplexer](#multiplexer).

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

**[BROWSER-ISOLATION.md](BROWSER-ISOLATION.md)** explains the whole mechanism
from first principles, with diagrams: every term, every hop a request takes,
what each extension contributes, and an honest account of what is not isolated.
What follows here is the operational summary.

Per context:

```
Zen container "digi3"
  -> SOCKS5 127.0.0.1:11081            (host, wsproxy-digi3.service)
  -> ~/.local/share/wsproxy/digi3/socks.sock
  -> /var/lib/wsproxy/socks.sock       (container, wsproxy-bridge.service)
  -> 127.0.0.1:1080                    (container, wsproxy-socks.service)
  -> digi3's netns / resolver / VPN
```

A UNIX socket rather than a port because it is a filesystem object: it crosses
the network-namespace boundary without weakening it. The host always dials in,
the container never learns a route back. Each container's own mount at
`/var/lib/wsproxy/` holds nothing but its own socket -- verified: `ls` there
from inside `digi3` prints `socks.sock` alone.

That mount guards against picking the wrong path by accident; it is not a
boundary against code already running inside a container. distrobox
bind-mounts the whole host home into every container besides, so the
directory holding all three sockets is reachable too: `ls -l
~/.local/share/wsproxy/*/socks.sock` from inside `digi3` lists digi3, personal
and stellium, mode `srw-------`, owned by the same uid the container runs as.
Connecting to a neighbour's socket from there gets back a SOCKS5 greeting, the
same as connecting to its own -- reaching a neighbour's proxy and leaving
through its VPN is one command away. What separates the contexts is the
network namespace at the end of the chain; the socket in the middle separates
nothing. [BROWSER-ISOLATION.md](BROWSER-ISOLATION.md) documents the identical
route with socat.

The list of contexts and ports is `contexts:` in `home/.chezmoidata.yaml`.
Adding a context means adding one entry there and running `chezmoi apply`.

After changing anything:

```sh
ss -ltnp | grep -E '1108[0-9]'                                   # bridges listen
ls -l ~/.local/share/wsproxy/*/socks.sock                        # containers answer
curl -s --socks5-hostname 127.0.0.1:11081 https://api.ipify.org  # end to end
distrobox enter digi3 -- ls /var/lib/wsproxy                     # only its own socket
ls ~/.config/zen/*/extensions/                                   # policy took
```

Extensions arrive through a system policy file, and its directory is derived
from the application name: Zen reads `/etc/zen/policies/policies.json`, not
`/etc/firefox/policies/policies.json`. A policy at the wrong path is silent --
the browser starts normally and simply has no extensions, which means no
container boundary. Hence the last check above, and `about:policies` -> Active.

### Routing test

Existence checks prove the parts are there. They do not prove a tab's traffic
went where it should: a proxy assigned to the wrong container, `proxyDNS` left
off, or a name in `ext+container:` that does not match a container (the
extension then creates it silently, without a proxy) all look fine from
outside. Comparing public IPs does not discriminate either while no context
has a VPN. A container's own loopback does.

`/var/tmp` and not `/tmp`: distrobox bind-mounts the host's `/tmp` into every
container, so a marker written there would be one file shared by all three and
the test would report the same name for every channel. `podman exec -d` and
not a backgrounded `distrobox enter`: the listener is killed with the exec
session, `setsid` included.

Reading the marker from a tab needs
`network.proxy.allow_hijacking_localhost`, which `user.js` turns on. Gecko
exempts localhost from proxying by default, which would send the request to
the host instead and fail with "unable to connect".

```sh
for c in digi3 stellium personal; do
  distrobox enter "$c" -- sh -c "printf 'HTTP/1.0 200 OK\r\nContent-Type: text/plain\r\n\r\n%s\n' \"\$(. /run/.containerenv; echo \$name)\" > /var/tmp/whoami.http"
  podman exec -d "$c" sh -c 'socat TCP-LISTEN:8099,bind=127.0.0.1,fork,reuseaddr SYSTEM:"cat /var/tmp/whoami.http"'
done

curl -s --max-time 5 http://127.0.0.1:8099/            # must fail: host has nothing there
for p in 11081 11082 11083; do
  printf '%s -> ' "$p"
  curl -s --socks5-hostname "127.0.0.1:$p" http://127.0.0.1:8099/
done                                                    # must print digi3, stellium, personal
```

Then open `http://127.0.0.1:8099/` from each Zen workspace: the page must name
that workspace's context. From `scratch` it must not load at all. Clean up:

```sh
for c in digi3 stellium personal; do
  distrobox enter "$c" -- sh -c 'pkill -f "TCP-LISTEN:8099" || true; rm -f /var/tmp/whoami.http'
done
```

### Set up automatically

The parts that used to be twenty minutes of clicking now come out of
`contexts:` like everything else:

| What | How |
|---|---|
| Containers, with names, colours and icons | the `Containers` enterprise policy, which replaces the built-in set on a fresh profile |
| A SOCKS proxy and remote DNS per container | a generated extension, `/usr/local/lib/zen-context-proxy.xpi`, installed `force_installed` from a `file://` URL |
| One space per context, bound to its container | `run_after_43-zen-spaces.sh` writes `zen-sessions.jsonlz4` |

The extension exists because doing this in Multi-Account Containers by hand
had two silent failure modes: `socks5://` parses to nothing there, and the
proxy field does not appear at all until an optional permission is granted.
Neither says a word when it goes wrong. It also creates any container it
cannot find by name, which closes the last one -- a hand-typed name that
matches nothing.

Do **not** also set proxies in Multi-Account Containers. One owner is enough,
and two disagreeing ones would be invisible.

The space seeding is deliberately timid, because that file also holds every
open tab and the format is Zen's internal one. It refuses if Zen is running,
if the profile has any tab, or if a space is already named after a context.
So on a fresh machine: `chezmoi apply`, launch Zen once so the profile and
containers exist, quit, `chezmoi apply` again.

### Configured by hand

What is left, once:

1. **Temporary Containers** -> automatic mode.
2. **Container sync off.** Multi-Account Containers -> *Enable
   synchronization* shares container names and site assignments through a
   Firefox Account. That is a list of every context and its domains, held in
   one place off this machine.
3. **"Always Open in Container" rules** go **only** on domains unique to one
   context. Never on shared ones such as `dev.azure.com`, `portal.azure.com`,
   `teams.microsoft.com` or `login.microsoftonline.com`: a domain rule *pulls*
   a link out of its current container.
4. **Bookmarks** rewritten as `ext+container:name=<Context>&url=<encoded>`. The
   container belongs in the link, not in the ambient context: otherwise a
   bookmark for stellium clicked from the digi3 workspace lands in digi3.
   `zen-open <context> <url>` builds the string; it is then visible in the
   address bar of the tab it opens.
5. **Pinned tabs and Essentials** per workspace, so reaching a frequent
   resource needs neither a typed address nor a bookmark.
6. **Bitwarden**: auto-fill on page load off; URI match detection `Never` for
   the shared Microsoft domains, `Host` for unique ones; one account per
   context.
7. `about:logins` emptied.

Not available, despite what an earlier version of this file claimed: *Open
external links in a container* 1.0.3 has no HMAC signing and no options page
at all. A page that feeds an `ext+container:` link therefore picks the
container, which is only bounded by the threat model putting hostile pages out
of scope.

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
