---
covers:
  features: []
  paths: []
---

# Glossary

Words this repo uses in its own way. Standard technology is not here.

| Term | Meaning |
|---|---|
| bridge | `socat` pair publishing a container's SOCKS proxy onto host `127.0.0.1:<socks>` over a UNIX socket. |
| context | Work identity from `contexts:` in `home/.chezmoidata.yaml`; the name selects a distrobox container, socks port, Zen container, space, bookmarks and SSH keys ([isolation.md](isolation.md)). |
| context-badge | `home/.chezmoitemplates/context-badge`: name and colour of the prompt tag, `host` outside a container. |
| `covers` | Doc frontmatter: feature keys and git pathspecs that doc covers; enforced by `tools/gen-catalog.sh`. |
| `enabled` | Selected feature keys in `~/.config/chezmoi/chezmoi.toml`; templates test `has "x" .enabled`. |
| `env` | chezmoi data `host` or `container`; picks which half of a script applies. |
| Essentials | Zen's pinned tiles above a space's tab list; stored in the session file, not in bookmarks. |
| `ext+container:` | URI scheme of the external-links extension: target Zen container baked into the link. |
| feature | Entry under `features:` in `home/.chezmoidata.yaml` (key, label, `scope`, `needs`, packages); the unit of installation. |
| herdr | Third-party host multiplexer; `~/.local/bin/work` opens one workspace per context in it ([multiplexer.md](multiplexer.md)). |
| home | The `plain_context`: no proxy, no distrobox container, traffic straight off the host. |
| Junction | Third-party app made default http(s) handler; the picker asking which context opens a link. |
| next steps | Checklist printed by `run_after_zz-next-steps.sh.tmpl`: pending manual steps as paste-ready commands. |
| `scope` | Feature field `both`/`host`/`container`: where that feature makes sense. |
| slice-run | `~/.local/bin/slice-run`: runs a command in a named systemd slice under a collision-free scope name. |
| space | Zen layout bound to a Firefox container, so entering it brings that container's cookies and proxy ([isolation-browser.md](isolation-browser.md)). |
| Space Routing | Zen rule "URL matches -> open in this space"; first match wins and pulls the link out of its current container. |
| wsproxy | The bridge subsystem and its socket dir `~/.local/share/wsproxy/<context>/` (`socks.sock`, `links.sock`) ([isolation-network.md](isolation-network.md)). |
| zen-open | `/usr/local/bin/zen-open` opens a URL in a Zen container; `zen-open-recv` is the host end of `links.sock`. |
