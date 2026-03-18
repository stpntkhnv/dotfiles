#!/bin/bash
set -euo pipefail

if [[ -z "${CONTAINER_ID:-}" ]]; then
    echo "Not inside a distrobox container, skipping package installation"
    exit 0
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
    freetds \
    git \
    glibc-locales \
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
    zsh \
    azure-cli

if ! command -v yay &>/dev/null; then
    echo "Installing yay (AUR helper)..."
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
    cd -
    rm -rf "$tmpdir"
fi

echo "Installing AUR packages via yay..."
yay -S --noconfirm --needed \
    teams-for-linux

if ! command -v azd &>/dev/null; then
    echo "Installing Azure Developer CLI (azd)..."
    curl -fsSL https://aka.ms/install-azd.sh | bash
fi

echo "Setting up npm global directory..."
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"

echo "Package installation complete"
