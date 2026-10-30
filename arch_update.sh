#!/usr/bin/env bash

# Configuration

LOG_DIR="${HOME}/.local/state/arch-update"

# Core functions

confirm() {
  local response

  read -r -p "$1 [Y/N]: " response
  [[ "$response" =~ ^[Yy]$ ]]
}

# Checks

checks() {
  if [[ $EUID -eq 0 ]]; then
    echo "Do not run this script as root!"
    exit 1
  fi

  if ! command -v pacman &>/dev/null; then
    echo "Pacman not found!"
    exit 1
  fi

  if ! command -v sudo &>/dev/null; then
    echo "Sudo not found!"
    exit 1
  fi

  sudo -v

  echo "Pre-checks completed."
}

# Update Offical Packages

update_system() {
  echo "Updating Arch Linux Packages..."

  sudo pacman -Syu

  echo "Offical packages updated."
}

# Cleanup

clean_cache() {
  echo "Cleaning package cache..."

  if command -v paccache &>/dev/null; then
    sudo paccache -r
    echo "Package cache cleaned."
  else
    echo "paccache not installed."
    echo "Install pacman-contrib to enable cache cleaning."
  fi
}

remove_orphans() {
  echo "Checking for orphaned packages..."

  local orphans
  orphans=$(pacman -Qdtq || true)

  if [[ -z "$orphans" ]]; then

    echo "No orphaned packages found."
    return
  fi

  echo "$orphans"

  if confirm "Remove orphaned packages?"; then
    mapfile -t orphan_array <<<"$orphans"
    sudo pacman -Rns -- "${orphan_array[@]}"

    echo "Orphaned packages removed."
  else
    echo "Skipping orphan removal."
  fi
}

checks
update_system
clean_cache
remove_orphans
