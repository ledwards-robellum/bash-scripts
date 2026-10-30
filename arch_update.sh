#!/usr/bin/env bash

# Script to update Arch-Based distrubtions
# Created by Logan Edwards

# Configuration

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Basically ensures script exits if a part fails:

set -Eeuo pipefail

LOG_DIR="${HOME}/.local/state/arch-update"

# Core functions

info() {
  echo -e "${BLUE}[INFO]${RESET} $*"
}

success() {
  echo -e "${GREEN}[SUCCESS]${RESET} $*"
}

warning() {
  echo -e "${YELLOW}[WARNING]${RESET} $*"
}

error() {
  echo -e "${RED}[ERROR]${RESET} $*"
}

confirm() {
  local response

  read -r -p "$1 [Y/n]: " response
  [[ "$response" =~ ^[Yy]$ ]]
}

# Checks

checks() {
  info "Running pre-checks..."

  if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root!"
    exit 1
  fi

  if ! command -v pacman &>/dev/null; then
    error "Pacman not found!"
    exit 1
  fi

  if ! command -v sudo &>/dev/null; then
    error "Sudo not found!"
    exit 1
  fi

  sudo -v

  success "Pre-checks completed."
}

# Update Offical Packages

update_system() {
  echo "----------------------------------------------------------------"
  info "Updating Arch Linux Packages..."

  sudo pacman -Syu

  success "Offical packages updated."
}

# Update AUR Packages

update_aur() {
  echo "----------------------------------------------------------------"
  if command -v paru &>/dev/null; then
    info "Updating AUR using paru..."
    paru -Sua
  elif command -v yay &>/dev/null; then
    info "Updating AUR using yay..."
    yay -Sua
  else
    warning "No AUR helper detected! Skipping AUR updates."
  fi
}

# Cleanup

clean_cache() {
  echo "----------------------------------------------------------------"
  info "Cleaning package cache..."

  if command -v paccache &>/dev/null; then
    sudo paccache -r
    success "Package cache cleaned."
  else
    warning "paccache not installed."
    error "Install pacman-contrib to enable cache cleaning."
  fi
}

remove_orphans() {
  echo "----------------------------------------------------------------"
  info "Checking for orphaned packages..."

  local orphans
  orphans=$(pacman -Qdtq || true)

  if [[ -z "$orphans" ]]; then

    info "No orphaned packages found."
    return
  fi

  echo "$orphans"

  if confirm "Remove orphaned packages?"; then
    mapfile -t orphan_array <<<"$orphans"
    sudo pacman -Rns -- "${orphan_array[@]}"

    success "Orphaned packages removed."
  else
    info "Skipping orphan removal."
  fi
}

# Check Failed Services

check_services() {
  echo "----------------------------------------------------------------"
  info "Checking for failed systemd services..."

  systemctl --failed --no-pager || true
}

check_reboot() {
  echo "----------------------------------------------------------------"
  info "Checking installed kernel..."

  local running_kernel
  local installed_kernel

  running_kernel=$(uname -r)
  installed_kernel=$(pacman -Q linux 2>/dev/null || true)

  info "Running kernel: ${running_kernel}"
  info "Installed kernel: ${installed_kernel:-Not installed}"

  warning "If the kernel, systemd, or critical libraries were updated, consider rebooting."
}

main() {
  echo
  echo "================================================================"
  echo "                    ARCH LINUX SYSTEM UPDATE                    "
  echo "================================================================"
  echo

  checks
  update_system
  update_aur
  clean_cache
  remove_orphans
  check_services
  check_reboot

  echo
  echo "================================================================"
  echo "                     SYSTEM UPDATE COMPLETE                     "
  echo "================================================================"
  echo
}

main
