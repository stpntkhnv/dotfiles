---
covers:
  features: [killswitch]
  paths:
    - home/.chezmoiscripts/run_onchange_after_39-killswitch.sh.tmpl
---

# Kill-switch

## What it does

Feature `killswitch`, `scope: container`, no `default`. Default-drop nftables
output chain in the container netns: egress bypassing the VPN dies instead of
taking a direct route. Covers all netns traffic, not just the browser bridge
([isolation-network.md](isolation-network.md)). Threat model:
[isolation.md](isolation.md).

## Files

| Path | Role |
|---|---|
| `home/.chezmoiscripts/run_onchange_after_39-killswitch.sh.tmpl` | Writes the files below; enables the unit only if the config is filled |
| `/etc/killswitch.conf` | Four `VPN_*` vars. `600 root:root`, written once (`if [[ ! -f "$CONF" ]]`), then hand-edited |
| `/usr/local/bin/killswitch-apply`, `/etc/systemd/system/killswitch.service` | Rewritten every apply. Script `755`, feeds `nft -f -`; unit `oneshot`, `RemainAfterExit=yes`, `ExecStop` drops the table |

## How it works

- `table inet killswitch`, chain `output`, `policy drop`; accepts loopback,
  `$VPN_IF`, `ct state established,related`, plus the endpoint hole, emitted only
  if `VPN_ENDPOINT` and `VPN_PORT` are both set.
- `table` / `delete table` / full definition reach `nft -f -` in one transaction:
  reruns idempotent, no half-open window. `nftables` comes from `container-base`
  ([containers.md](containers.md)); no packages declared here.
- Two independent refusals to cut the network: `killswitch-apply` exits `1`
  before touching `nft` if `VPN_IF` is empty; the script enables the unit only if
  `grep -q '^VPN_IF=.\+' "$CONF"`. Opt-in is a third barrier: lose one of those
  and only the opted-in container is hit.

## Constraints

- Enable it in the container that gets the VPN; the checklist offers it only
  there (`.chezmoi.toml.tmpl`, `eq .scope $env`).
- `run_onchange` watches the script text, not `/etc/killswitch.conf`: filling the
  config later needs `systemctl enable --now` by hand.
- `600` is set only at creation; loosened permissions are never restored.
- IPv6 needs no rule: `inet` is a hybrid v4/v6 family, `policy drop` covers both.
- One IPv4 endpoint. The script comment claims every other shape fails closed;
  wrong twice (`man nft` v1.1.6, 2026-07-31; unreproduced, `nft` wants root even
  for `-c`): a host name is accepted (`ip daddr` is `ipv4_addr`, resolved by the
  system resolver), so several A records widen the hole; and a parse failure (two
  addresses, IPv6 literal, dead name) rolls back atomically - on a first apply
  that leaves no table, netns open.
- OpenZiti has no kill-switch and no branch here ([network.md](network.md)).

## Verify

```sh
# each line inside: distrobox enter <ctx> --
systemctl status killswitch.service      # disabled while config empty, else active (exited)
sudo nft list table inet killswitch      # chain output, policy drop, the accepts
curl -s --max-time 3 https://ifconfig.me # must time out under a live VPN
```

Never seen firing live: no container here has had a real VPN (2026-07-31).

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| All network gone, VPN included | Endpoint/port empty or wrong, or stale `VPN_IF` | Fix config, `systemctl restart killswitch.service` |
| Unit `disabled` though config is filled | Config filled after the script ran | `systemctl enable --now killswitch.service` |
| Endpoint edit had no effect | Parse failure, rollback kept the old table | `journalctl -u killswitch.service`, fix, `restart` |
