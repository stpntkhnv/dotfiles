#!/bin/bash
set -euo pipefail

if [[ -z "${CONTAINER_ID:-}" ]]; then
    echo "Not inside a distrobox container, skipping package installation"
    exit 0
fi

# The official archlinux:latest Docker image ships with an empty mirrorlist
# and no Include directive for [extra]. Bootstrap both before any pacman op.
if ! grep -q '^Server' /etc/pacman.d/mirrorlist 2>/dev/null; then
    echo "Bootstrapping pacman mirrorlist..."
    curl -fsSL "https://archlinux.org/mirrorlist/?country=all&protocol=https&use_mirror_status=on" \
        | sed -e 's/^#Server/Server/' -e '/^#/d' \
        | sudo tee /etc/pacman.d/mirrorlist >/dev/null
fi
if grep -q '^\[extra\]' /etc/pacman.conf && \
   ! awk '/^\[extra\]/{f=1;next} f&&/^Include/{print;exit} /^\[/{f=0}' /etc/pacman.conf | grep -q .; then
    echo "Adding [extra] Include directive to /etc/pacman.conf..."
    sudo sed -i '/^\[extra\]/a Include = /etc/pacman.d/mirrorlist' /etc/pacman.conf
fi

echo "Installing base packages via pacman..."
sudo pacman -Syu --noconfirm --needed \
    base-devel \
    alsa-plugins \
    bat \
    bc \
    btop \
    diffutils \
    docker \
    dotnet-sdk \
    aspnet-runtime \
    aspnet-targeting-pack \
    eza \
    fd \
    firefox \
    freetds \
    git \
    glibc-locales \
    go \
    inetutils \
    lazydocker \
    lazygit \
    less \
    lsof \
    man-db \
    man-pages \
    mesa \
    mtr \
    neovim \
    nodejs \
    npm \
    nss-mdns \
    openssh \
    pigz \
    ripgrep \
    rsync \
    sox \
    sudo \
    tcpdump \
    time \
    tmux \
    traceroute \
    tree-sitter-cli \
    tree \
    unzip \
    vte-common \
    vulkan-intel \
    vulkan-radeon \
    wget \
    words \
    xorg-xauth \
    zip \
    zoxide \
    zsh

if ! command -v yay &>/dev/null; then
    echo "Installing yay (AUR helper)..."
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
    cd -
    rm -rf "$tmpdir"
fi

if ! command -v code &>/dev/null; then
    echo "Installing Visual Studio Code..."
    yay -S --noconfirm --needed visual-studio-code-bin
fi

if ! command -v devtunnel &>/dev/null; then
    echo "Installing Microsoft Dev Tunnels CLI..."
    yay -S --noconfirm --needed devtunnel
fi

echo "Setting up npm global directory..."
mkdir -p "$HOME/.npm-global"
# Only set when needed: `npm config set` rewrites ~/.npmrc with an absolute
# prefix path, creating a permanent chezmoi conflict with the managed file.
if [[ "$(npm config get prefix)" != "$HOME/.npm-global" ]]; then
    npm config set prefix "$HOME/.npm-global"
fi

echo "Installing Claude Code CLI..."
"$HOME/.npm-global/bin/npm" install -g @anthropic-ai/claude-code 2>/dev/null \
    || npm install -g @anthropic-ai/claude-code

echo "Installing Playwright browsers..."
npx playwright install chromium

echo "Configuring Firefox extensions via policies..."
sudo mkdir -p /usr/lib/firefox/distribution
sudo tee /usr/lib/firefox/distribution/policies.json > /dev/null <<'POLICIES'
{
  "policies": {
    "ExtensionSettings": {
      "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/auto-tab-discard/latest.xpi"
      }
    }
  }
}
POLICIES

echo "Base package installation complete"
