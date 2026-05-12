#!/bin/bash
#
# Downgrade util-linux to 2.41.3-2 inside an Arch container.
#
# util-linux 2.42 has a regression where `su --pty` passes --pty to the
# invoked shell instead of handling it, which breaks `distrobox enter` for
# containers created with init=true (see distrobox#2052 and util-linux PR#4185).
# The fix is merged upstream but v2.42.1 is not yet released; until it lands
# in the Arch repos this downgrade is the workaround.
#
# Idempotent: no-op if the running util-linux is already not 2.42.x.
#
set -euo pipefail

if ! command -v pacman >/dev/null 2>&1; then
    echo "util-linux-fix: pacman not available, skipping"
    exit 0
fi

current=$(pacman -Q util-linux 2>/dev/null | awk '{print $2}')
case "$current" in
    2.42-*|2.42.0*)
        ;;
    *)
        echo "util-linux-fix: current version $current is not affected, nothing to do"
        exit 0
        ;;
esac

echo "util-linux-fix: downgrading util-linux $current -> 2.41.3-2"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

curl -fsSLO https://archive.archlinux.org/packages/u/util-linux/util-linux-2.41.3-2-x86_64.pkg.tar.zst
curl -fsSLO https://archive.archlinux.org/packages/u/util-linux-libs/util-linux-libs-2.41.3-2-x86_64.pkg.tar.zst

# Use sudo if not root (script may be sourced from a user context)
SUDO=""
if [[ $EUID -ne 0 ]]; then
    SUDO=sudo
fi

$SUDO pacman -Udd --noconfirm \
    util-linux-2.41.3-2-x86_64.pkg.tar.zst \
    util-linux-libs-2.41.3-2-x86_64.pkg.tar.zst

# Pin so the next -Syu doesn't upgrade back to the broken version
if ! grep -q '^IgnorePkg.*util-linux' /etc/pacman.conf; then
    $SUDO sed -i '/^\[options\]/a IgnorePkg = util-linux util-linux-libs' /etc/pacman.conf
    echo "util-linux-fix: pinned util-linux/util-linux-libs via IgnorePkg"
fi

echo "util-linux-fix: done"
