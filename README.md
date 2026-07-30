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
`env HERDR_AGENT=claude distrobox enter --no-workdir <context>` into each
space's root pane, and then attaches the TUI. Detach with `ctrl+b`, `q`: the
server is headless and outlives the client, so the panes carry on.

The `HERDR_AGENT` part is the same label the context aliases carry, and for the
same reason -- see [What you type inside a pane](#what-you-type-inside-a-pane).
It is here so that a space opened by `work` behaves like one opened by hand.

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
digi3         # HERDR_AGENT=claude distrobox enter --no-workdir digi3
digi3-claude  # HERDR_AGENT=claude distrobox enter --no-workdir digi3 -- claude
digi3-tmux    # distrobox enter --no-workdir digi3 -- tmux -L digi3 new-session -A -s work
```

The twins are conditional: `-claude` renders only while `herdr` is ticked,
`-tmux` only while `tmux` is. The `HERDR_AGENT=claude` on the bare name is
conditional the same way -- without herdr there is nothing to label the pane
for.

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

`HERDR_AGENT=claude` is what puts the agent in herdr's sidebar, and it is on the
**entry** and not only on the `-claude` twin. herdr identifies the agent in a
pane from the foreground process group on the host side. Through `distrobox
enter` that group is `distrobox` and `podman`; the real claude runs on its own
pty inside the container, where herdr cannot see it. So without the label a
claude started by hand -- enter the shell first, type `claude` after, which is
the ordinary way to work -- is in no agent list at all, and the sidebar stays
empty. That is the whole reason herdr is here.

Labelling the pane at entry is enough, because only the identification is
missing: the screen itself does cross the container boundary, so herdr reads the
state off it live rather than freezing at whatever was reported. Measured on
0.7.5, real claude in a container pane, entered as a plain shell and launched by
hand:

| Pane holds | herdr says |
|---|---|
| the context shell, nothing else | `claude`, `idle`, no rule matched |
| claude at its prompt | `claude`, `idle`, rule `live_prompt_box`, title `✳ Claude Code` |
| claude answering | `working`, title `⠐ Claude Code`, then `idle` or `done` |

The label has to be on that command and nowhere else. Exporting `HERDR_AGENT`
inside the container does nothing at all -- verified, the pane stays unlabelled
-- because herdr reads the environment of the process it spawned itself, which
is the host-side `podman`. Exporting it from `.bashrc` instead would go the other
way and label every pane on the machine, host panes included.

The price is a row that arrives early: a pane holding nothing but a context
shell, or tmux, or an editor, is listed as an idle `claude` agent. Nothing is
claimed to be working, so the state is honest; the row is simply there before
the agent is.

The other route was rejected after measuring it. herdr also takes pushed state
over its socket (`pane.report_agent`), and that works from inside a container --
`HERDR_PANE_ID` and `HERDR_SOCKET_PATH` are passed in by distrobox, the socket
path resolves, the binary is there. But a pushed state takes authority and
freezes the sidebar: with `idle` reported, the screen read `working` and the row
stayed `idle`. Releasing the authority drops the label with it, so there is no
"identify only, let the screen drive it". That route therefore needs every
transition reported from claude's own hooks, in every container's config, to
replace what one word already does.

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

## Sync

Notes and phone photos stay in step across machines through
[Syncthing](https://syncthing.net), driven from `home/.chezmoidata.yaml` under
a `syncthing:` key rather than clicked together in the web UI. Four folders:

| id | path | type on host | participants | versioning |
|---|---|---|---|---|
| `kb` | `~/Documents/Notes/kb` | `sendreceive` | desktop, laptop | staggered |
| `personal` | `~/Documents/Notes/personal` | `sendreceive` | desktop, laptop, phone | staggered |
| `kb-archive` | `~/Documents/Notes/kb-archive` | `sendreceive` | desktop, laptop | none |
| `camera` | `~/Pictures/Camera` | `receiveonly` | desktop, phone | none |

`type` is Syncthing's own vocabulary: `sendreceive` folders sync both ways,
`receiveonly` accepts incoming changes but never sends its own. A folder only
gets created on the machines named in its own `devices` -- the laptop is not
listed under `camera`, so the laptop gets no `camera` folder at all, not an
empty one. Ids are spelled out by hand (`kb`, `personal`, `kb-archive`,
`camera`) rather than left to Syncthing's random generator, because the
phone's app needs the same id typed in by hand and it has to match to the
character.

This change also adds `obsidian` as a feature, since the vaults Syncthing
carries need something to open them. On a machine that already had this
repository before this change, neither key is there: `syncthing` and
`obsidian` are new asked features, and a stored `data.enabled` never gains a
new key by itself (see [Adding a program](#adding-a-program)). Left alone, a
plain `chezmoi apply` on that machine installs neither and configures
neither -- nothing errors, so it gets a clean apply that installs nothing and
says nothing. Add both keys to `data.enabled` by hand before applying.

Syncthing runs on the host only, not inside every distrobox container. It
does not need to: distrobox already mounts the whole host home directory tree
into each container, so a folder kept in sync on the host shows up in
`digi3`, `stellium` and `personal` by itself. This is already relied on --
the agent knowledge base's own machine index,
`~/system/.claude/rules/machine-index.md`, is a symlink into the vault, and
it resolves to the same file whether followed from the host or from inside a
container. A daemon per container would move the same bytes again, need its
own device identity and its own port, and would have to punch a hole through
that container's own network namespace to do it. Nothing is gained.

`camera` is an inbox, not an archive. `receiveonly` does not mean the host
ignores what the phone deletes -- a delete from the phone is applied here
like anywhere else. What `receiveonly` actually protects is the other
direction: the host never pushes its own changes back, so a photo can be
carried out of `~/Pictures/Camera` into permanent storage by hand, and the
phone's gallery never notices. Clearing space on the phone's gallery still
empties this folder too.

Device IDs and addresses are not in the catalogue. They live in
`~/.config/chezmoi/chezmoi.toml`, per machine:

```toml
[data.syncthing.devices]
  desktop = { id = "<device-id>", addresses = ["dynamic", "tcp://<name>.<tailnet>.ts.net:22000"] }
  laptop  = { id = "<device-id>", addresses = ["dynamic", "tcp://<name>.<tailnet>.ts.net:22000"] }
  phone   = { id = "<device-id>", addresses = ["dynamic", "tcp://<name>.<tailnet>.ts.net:22000"] }
```

The catalogue names only folders and logical participants (`desktop`,
`laptop`, `phone`). This repository is public, and a device ID is a stable
identifier of a machine that exists; publishing it, together with its
address and how many such machines there are, gives away a correlation for
nothing in return.

Discovery is local plus tailnet (the private network [Tailscale](https://tailscale.com)
joins these machines to), nothing further. On the same network,
`localAnnounceEnabled` finds the other machine directly; global announce,
relays and NAT traversal are all off, so these machines are not advertised
anywhere beyond that. That is why every entry above carries two addresses --
`dynamic` alone only resolves inside the LAN, so reaching a device from
anywhere else needs the static `tcp://<name>.<tailnet>.ts.net:22000` form
too. The phone is the device most likely to be off the home network, and it
has to actually be joined to the tailnet, or that second address means
nothing.

`sudo ufw` gets rules for `22000/tcp`, `22000/udp` and `21027/udp`. Without
them the default-deny-incoming firewall blocks both directions and it fails
quietly: the web UI works, both devices are listed, and the status just sits
on Disconnected. An open port here is not an open door -- Syncthing checks
the connecting device's certificate on every attempt and rejects anything it
does not already know.

Syncthing runs as a user service, because it has to read `~/Documents` and a
system unit could not. The consequence: a machine that is powered on but not
logged in does not sync. `loginctl enable-linger` removes that limit for
whoever wants otherwise; it is not turned on here, on purpose.

The notes vault's own path is owned by a different repository, `claudefiles`,
which is what actually populates `~/Documents/Notes/kb`. After this, the same
path exists a second time, as the `kb` folder's `path` above. The two can
drift silently -- agents keep reading and writing the vault at their own
path, Syncthing keeps faithfully syncing the directory next to it, and the
first sign is an empty vault on the other machine. Reconciling them is a
`chezmoi apply` next-steps check, not something this file can enforce: it
compares the two paths and prints both when they disagree.

### New machine

Pairing is mutual; one machine acting alone cannot finish it.

1. On the new machine, `chezmoi apply`. The script creates a Syncthing
   identity, starts the service and exits; next-steps prints that machine's
   device ID.
2. That ID gets added to `[data.syncthing.devices]` on every machine that is
   already running. This is the only step in the whole setup where an action
   on one machine requires an action on another, and skipping it neither
   errors nor warns -- both sides simply look configured and never connect.
3. `chezmoi apply` on each of those already-running machines.
4. The complete map, all machines together, is copied onto the new machine,
   and `chezmoi apply` runs there again.
5. The phone is added by hand, on both sides -- see below.

### Phone

Syncthing on Android is not touched by chezmoi at all; it is set up once, by
hand, in the app:

1. Join the tailnet.
2. Add the computer as a device, using its device ID.
3. Create `personal` and `camera` as folders with exactly those ids. A typo
   here is not an error: Syncthing accepts it and quietly creates a second,
   unrelated folder instead.
4. Set `camera` to Send Only, matching the host's `receiveonly`.
5. Leave `personal` two-way.

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
the keybind and pokes the already-running process instead. Handy documents two
ways to do that, Unix signals and CLI flags; the binding here uses the flag,
for reasons in [Signals](#signals) below. That binding and `spawn-at-startup`
live in `home/dot_config/niri/voice.kdl.tmpl`, which `config.kdl` includes
unconditionally and which renders to a comment-only file when the feature is
off.

After installing, launch Handy once and download a model (Settings → Model).
The pinned model is Whisper Large v3 Q8_0 (~1.7 GB) -- see
[Punctuation](#punctuation) for why. Pulling the weights is still a manual,
one-time step through Handy's own UI; `44-handy-settings` only selects the
model afterward, in the settings file, on every apply.

### Punctuation

Whisper picks a transcription style at the first token of every 30-second
decode window and holds it, autoregressively, to the end of that window. With
nothing to pin the choice, of 40 transcripts longer than 60 characters, 6
carried no sentence-ending punctuation at all, and two more began unpunctuated
and switched to clean prose partway through, at a decode-window boundary.

Handy's only lever on that is the whisper `initial_prompt`, and its only
source is the Custom Words list -- which the UI restricts to single
space-free words, ruling out a prompt-shaped sentence outright. So
`44-handy-settings` writes the seed straight into `custom_words` through
`jq`, on every apply, bypassing that restriction rather than working inside
it.

The rule that matters most: the seed has to be **last** in the list, and it
has to end with a full stop. Handy joins `custom_words` with `", "` before
handing the result to Whisper as `initial_prompt`, so a seed that ends
mid-list -- because some other word got appended after it -- comes back
worse-punctuated than sending no prompt at all. This was measured, not
theorised. Anyone adding a technical term to `custom_words` later has to add
it *before* the seed, never after.

A separate benchmark built to test the fix -- 39 recordings, 34 of them
longer than 60 characters -- ran four conditions: turbo and large-v3, each
with and without the seed. Without it, both models still left 2 transcripts
with no sentence-ending punctuation at all, worst case 507 characters on
turbo and 733 on large-v3. With it, both dropped to 0 -- worst case 342 on
turbo+seed, 403 on large-v3+seed.

The model changed too, from turbo to large-v3, though not for punctuation --
both scored the same on that axis. Handy's own catalogue puts them close on
accuracy (89 against 87) and far apart on speed (23 against 35); neither
number is why the switch happened. What large-v3 gives instead is
Latin-script spelling: with the seed, turbo writes anglicisms like `Chizmoi`
and `GEMA`, large-v3 writes `chezmoi` and `Gemma`. Over the same corpus,
large-v3+seed produced 42 unique Latin-script tokens against turbo+seed's 34.

The price is latency: turbo+seed transcribes at a median of 272 ms (RTF
89.6), large-v3+seed at 622 ms (RTF 36.6).

The seed does not fix very long, rambling dictation, because `initial_prompt`
only pins the first 30-second window. On three recordings of 91, 137 and 106
seconds, large-v3 scored 544, 443 and 432 characters unpunctuated against
turbo's 500, 536 and 367 -- indistinguishable, which is the evidence that the
decode-window limit, not the model, is the cause.

| Key | What it does |
|---|---|
| **Mod+Shift+D** | dictate (`handy --toggle-transcription`) |

### Signals

Handy's own README offers two ways to drive it from a compositor keybind:
`pkill -USR2` to toggle transcription, `pkill -USR1` to toggle it with
post-processing. Both are unusable here, and the reason is worth writing down
because the surface symptom points at the wrong culprit.

WebKitGTK, the webview engine Tauri embeds on Linux, uses `SIGUSR1` internally:
JavaScriptCore suspends its own threads with it so the garbage collector can
scan their stacks. Handy registers a process-wide handler for that same signal
(`src-tauri/src/lib.rs`, `signal_handle.rs`), and the two uses collide in both
directions.

Outward, a `pkill -USR1` from the keybind kills the process. `signal-hook`, the
crate Handy registers through, chains rather than replaces: it calls the
previously installed handler after its own. So the signal reaches
JavaScriptCore's thread-suspend handler outside the collection protocol that
handler exists to serve, and it dereferences from there. Six coredumps here say
the same thing: frame #0 in `libjavascriptcoregtk-4.1`, frame #1 in `handy`,
frame #2 the libc signal trampoline, the interrupted context an ordinary
`ppoll` in the GTK main loop.

Inward is the bug that bites users who never send a signal at all. Every
collection delivers `SIGUSR1` inside Handy's own process, Handy's handler reads
it as a hotkey press, and on a toggle binding that starts a recording nobody
asked for -- or stops one that is still being spoken, transcribes the fragment
and pastes it. Upstream has it as
[#1660](https://github.com/cjpais/Handy/issues/1660), with a second report
measuring ten dictations destroyed in one morning, each cut at 122 seconds. The
fix, [#1267](https://github.com/cjpais/Handy/pull/1267), moves remote control to
`SIGRTMIN+1`/`+2`; it has been open since April and is not in 0.9.4. There is no
way to share the signal: filtering by sender was tried and hangs the app within
the hour, because Handy's handler consumes a delivery WebKit needs to receive.

So the binding uses `handy --toggle-transcription`, which is also what #1267
itself tells signal users to migrate to. The flag reaches the same
`send_transcription_input` the signal handler calls, so nothing about the
behaviour differs; the cost is spawning a process per keypress, measured at 60
ms.

This repository is not exposed to the phantom recordings either, and that is
not luck twice over: `overlay_style` is pinned to `none` by the settings patch.
The overlay is what keeps the webview busy during a recording, and a busy
webview is what makes the collector run often enough to matter.

### Typing the text out

`paste_method` is pinned to `external_script`, pointing at
`home/bin/executable_handy-type.sh`. Handy's own paste path drops characters on
Cyrillic: `wtype` builds a virtual keymap from the text's unique characters in
order of first appearance, and this stack silently eats keycodes #14 and #15 of
it -- across several dictations, exactly the 14th and 15th unique character
vanished, every occurrence of them. The script types in chunks of 12, which
keeps every keymap short enough that nothing lands on a dead keycode.

The script also flattens every run of whitespace holding a newline, carriage
return or tab into one space. `wtype` has no notion of text: it turns each
character into a key press, and libxkbcommon maps U+000A to keysym `Linefeed`,
which arrives as the byte Ctrl+J sends and which a terminal input line reads as
Enter. Dictating into Claude Code, a transcript an LLM cleanup pass had once
broken into three paragraphs submitted itself twice on the way in, the tail
left in the box (`history.db` rows 347 and 348). Measured at the time: 2 of 18
cleaned transcripts carried a newline inside the text, 0 of 18 raw ones did,
so Whisper was never the source. That cleanup pass is gone now, but the
flattening stays anyway: it costs nothing and turns "Whisper does not emit
newlines" from an observation into a guarantee.

Handy is a Tauri app whose paste path goes through a library that only speaks
X11, so `config.kdl` sets `DISPLAY :12` for `xwayland-satellite`. Without it the
typing fails with no visible error.

### Settings

The settings live in `settings_store.json`, which Handy owns and rewrites from
its own UI, so `run_after_44-handy-settings` patches the ten keys we care
about rather than the repository managing the file. Every one of them sits
under the top-level `settings` object; writing to the root instead is silent,
not an error.

On a fresh machine that file does not exist until Handy has started once, the
same shape as the Zen profiles: `chezmoi apply`, launch Handy and download a
Whisper model, `chezmoi apply` again.

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
