---
covers:
  features: [printing, bluetooth-fix, earlyoom]
  paths:
    - home/.chezmoiscripts/run_onchange_before_35-nvidia.sh.tmpl
    - home/.chezmoiscripts/run_onchange_before_50-bluetooth.sh.tmpl
    - home/.chezmoiscripts/run_onchange_before_30-system.sh.tmpl
---

# Hardware: NVIDIA, zram, earlyoom, services, printing, BT dongle

## What it does

Host only: NVIDIA driver + Vulkan, zram swap, `earlyoom`, unit enabling, CUPS,
autosuspend fix for one dongle. Features `printing`, `bluetooth-fix`,
`earlyoom`; NVIDIA is not a feature.

## Files

| Path | Role |
|---|---|
| `…30-system.sh.tmpl` | Middle third: zram + units. Rest: [keyboard.md](keyboard.md), [network.md](network.md) |
| `…35-nvidia.sh.tmpl` | Driver + Vulkan, gated on `.nvidia_driver` |
| `…50-bluetooth.sh.tmpl` | Dongle fix, gated on `bluetooth-fix` |
| Generated in `/etc` | `systemd/zram-generator.conf`, `modprobe.d/btusb.conf`, `udev/rules.d/50-bt-dongle-nosuspend.rules` |

## How it works

- **NVIDIA probe** in `home/.chezmoi.toml.tmpl` (`$hasNvidia`, `$gpuReady`):
  PCI class `0x030*` + vendor `0x10de`, then `/dev/nvidiactl` and the ICD.
  Kept in `data.nvidia_driver`, **not** `data.enabled`, and recomputed every
  `init`: once the ICD exists `promptBoolOnce` is unreachable and the field
  goes `false`. Harmless, `35-nvidia` rechecks the ICD.
- `35-nvidia` takes `nvidia-open` only if the sole kernel package is `linux`,
  else `nvidia-open-dkms` + headers per recognised kernel. No `cuda`: desktop
  and Whisper use Vulkan ([voice.md](voice.md)).
- **zram** conf is rewritten only if the literal `zram-size = ram / 2` line is
  absent; live apply needs `swapoff /dev/zram0 && systemctl restart
  systemd-zram-setup@zram0`. 15.6G zstd, 31 GiB RAM (2026-08-03).
- **earlyoom** (`host`, `always`), package defaults untouched: fires when
  available RAM **and** free swap are both under 10%. Global `MemAvailable`
  only, so blind to cache-free thrashing and to a cgroup at its own cap
  ([agents.md](agents.md)).
- **Units** through `enable_unit`: seven unconditional, plus `cups.socket`,
  `tailscaled`, `docker.socket` by feature. `sddm` is one of the seven but
  guarded: it fires only if nothing holds `display-manager.service`, which
  `greetd` does. User `podman.socket` goes past `enable_unit` and past `sudo`
  (`systemctl --user enable --now`). No `--now` except `tailscaled`, `ufw` and
  `podman.socket`, which the next step needs alive. Under `set -e` a unit whose package is missing kills the apply.
- **printing** (`default: true`) ships `cups-pk-helper` because
  DankMaterialShell drives printers through it, not because CUPS needs it. The
  `ufw allow mdns` rule revealing network printers: [network.md](network.md).
- **Dongle**: `btusb` autosuspends `10d7:b012` 2 s after `hci0` registers, mid
  HCI init, and it never answers - `Bluetooth: hci0: Opcode 0x1004 failed:
  -110` (`ETIMEDOUT`), so BlueZ registers no controller. `bluetooth-fix` adds
  no packages and takes effect at next boot. Not our bug: `enable_autosuspend`
  is btusb's own documented knob (`modinfo btusb`). The udev rule matches this
  vendor/product only.

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| `zram-size = ram / 2` | Default `min(ram/2, 4G)` gave 4 GiB, ran out twice: hang 2026-07-30, thrash 2026-08-02 | `ram` - badly compressible pages then eat RAM itself |
| Pin zstd | Survives a change of the kernel default (`CONFIG_ZRAM_DEF_COMP="zstd"` today, so it changes nothing) | Kernel default |
| `earlyoom` as `always` feature | Hand-installed 2026-07-30, would not survive a reinstall | `kernel.sysrq`, same investigation, still open |

## Verify

```sh
ls /dev/nvidiactl /usr/share/vulkan/icd.d/nvidia_icd.json  # both -> init stays quiet
zramctl                               # zram0 zstd 15.6G [SWAP]
systemctl is-active earlyoom.service   # active
grep PRODUCT /sys/class/bluetooth/hci0/device/uevent  # 10d7/b012/... -> hci0 is the dongle
bluetoothctl list                     # it is the default controller -> fix holds
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| "No Bluetooth adapters found" | `enable_autosuspend=0` not live yet, no reboot since apply | `systemctl stop bluetooth && modprobe -r btusb && modprobe btusb && systemctl start bluetooth` |
| Hard freeze under memory pressure | earlyoom needs RAM and swap both under 10%; cache-free thrash and capped cgroups are neither | `systemctl status earlyoom`, then the issue |

## See also

- [issues/2026-07-30-desktop-hang-out-of-memory.md](issues/2026-07-30-desktop-hang-out-of-memory.md); [workarounds.md](workarounds.md) - dongle evidence, plus the failed `pciutils` claim behind reading `/sys/bus/pci`
- Dongle upstream, searched 2026-07-31, nothing ties it to autosuspend: [btusb.c](https://github.com/torvalds/linux/blob/master/drivers/bluetooth/btusb.c) has `USB_DEVICE(0x10d7, 0xb012)` with the unrelated `BTUSB_ACTIONS_SEMI` quirk; [CSR force-suspend](https://yhbt.net/lore/all/906e95ce-b0e5-239e-f544-f34d8424c8da@gmail.com/) same bug class, other chip
