#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 <disk> <hostname> [-c <config-url>] [-y]"
  echo "  -h <hostname> : Required hostname for the new system"
  echo "  -c <config-url> : Optional URL to a NixOS configuration (default: https://github.com/RyanGibb/nixos.git)"
  echo "  -y : Run non-interactively (skip all prompts)"
  exit 1
}

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

URL="https://github.com/RyanGibb/nixos.git"
AUTO_YES=false

if [ $# -lt 2 ]; then
  usage
fi

DISK=$1
HOST=$2
shift 2

while getopts ":c:y" opt; do
  case $opt in
    c) URL="$OPTARG" ;;
    y) AUTO_YES=true ;;
    *) usage ;;
  esac
done

PART_SUFFIX=""
if [[ "$DISK" == *nvme* ]]; then
  PART_SUFFIX="p"
fi

echo "Partitioning $DISK..."
parted "$DISK" -- mklabel gpt
parted "$DISK" -- mkpart ESP fat32 1MB 512MB
parted "$DISK" -- mkpart primary 512MiB 100%
parted "$DISK" -- set 1 esp on

echo "Making file systems..."
mkfs.fat -F 32 -n boot "${DISK}${PART_SUFFIX}1"
mkfs.ext4 -L nixos "${DISK}${PART_SUFFIX}2"

echo "Mounting partitions..."
mount "${DISK}${PART_SUFFIX}2" /mnt
mkdir -p /mnt/boot
mount "${DISK}${PART_SUFFIX}1" /mnt/boot

if [ "$AUTO_YES" = false ]; then
  echo
  echo "Disk partitioning and mounting complete."
  echo "The following partitions have been created and mounted on $DISK:"
  echo "  - ${DISK}${PART_SUFFIX}1 (ESP, FAT32, /boot) mounted at /mnt/boot"
  echo "  - ${DISK}${PART_SUFFIX}2 (Primary, ext4, /) mounted at /mnt"
  echo
  echo "Do you want to use the NixOS configuration included in this ISO or from a remote git repository?"
  echo "1) Use local"
  echo "2) Use remote: $CONFIG_URL"
  read -r -p "Select an option [1/2] (default is 2): " config_choice
  config_choice=${config_choice:-2}
else
  config_choice=2
fi

mkdir -p /mnt/etc/nixos/
if [[ "$config_choice" == "1" ]]; then
  echo "Copying local configuration to /mnt/etc/nixos ..."
  cp -R /home/nixos/nixos /mnt/etc/nixos/
else
  echo "Cloning $URL to /mnt/etc/nixos ..."
  git clone "$URL" /mnt/etc/nixos
fi

echo "Generating configuration at /mnt/etc/nixos/hosts/$HOST ..."
mkdir -p /mnt/etc/nixos/hosts/"$HOST"
nixos-generate-config --show-hardware-config >> /mnt/etc/nixos/hosts/"$HOST"/hardware-configuration.nix
(cd /mnt/etc/nixos/hosts/"$HOST"; nix flake init -t /mnt/etc/nixos#host)

if [ "$AUTO_YES" = false ]; then
  echo
  read -r -p "Do you want to continue with the NixOS installation? [y/N] " response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Installation aborted by user."
    exit 0
  fi
fi

echo "Installing NixOS..."
nixos-install --root /mnt/ --flake /mnt/etc/nixos#"$HOST"

if [ "$AUTO_YES" = false ]; then
  echo
  read -r -p "Installation is complete. Do you want to reboot the system now? [y/N] " response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Reboot canceled by user. You may continue using the system."
    exit 0
  fi
fi

reboot
