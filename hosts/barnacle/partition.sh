#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Usage: $0 <disk>"
  exit 1
fi

DISK=$1
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

# then...

# mkdir -p /mnt/etc/nixos
# git clone https://github.com/RyanGibb/nixos.git /mnt/etc/nixos
# OR
# cp -R /home/nixos/nixos /mnt/etc/nixos/

# echo "Generating NixOS configuration..."
# nixos-generate-config --root /mnt

# ...

# nixos-install --root /mnt/ --flake /mnt/etc/nixos#host

