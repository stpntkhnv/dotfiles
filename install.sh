#!/bin/sh

set -e

if [ ! "$(command -v chezmoi)" ]; then
  bin_dir="$HOME/.local/bin"
  chezmoi="$bin_dir/chezmoi"
  if [ "$(command -v curl)" ]; then
    sh -c "$(curl -fsSL https://git.io/chezmoi)" -- -b "$bin_dir"
  elif [ "$(command -v wget)" ]; then
    sh -c "$(wget -qO- https://git.io/chezmoi)" -- -b "$bin_dir"
  else
    echo "To install chezmoi, you must have curl or wget installed." >&2
    exit 1
  fi
else
  chezmoi=chezmoi
fi

script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"
# Drop `set -e` so we can give the user a useful retry hint instead of just
# vanishing on script failure.
set +e
if [ -f "$script_dir/.chezmoiroot" ]; then
  "$chezmoi" init --apply "--source=$script_dir"
else
  "$chezmoi" init --apply stpntkhnv
fi
status=$?

if [ $status -ne 0 ]; then
  echo
  echo "Setup did not complete. To retry without losing answered prompts:"
  echo
  echo "  $chezmoi apply"
  echo
  echo "(Use the full path above if ~/.local/bin is not yet in PATH.)"
  exit $status
fi
