#!/usr/bin/env bash
# fix-uefi-boot — recreate the UEFI NVRAM boot entry for grub.
#
# A hard reset (or firmware reset) can wipe the UEFI NVRAM, dropping the boot
# entry that points at grub and leaving the machine unbootable. Boot the barnacle
# live USB and run this to recreate the entry.
#
# See: https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface#efibootmgr

set -euo pipefail

DISK="/dev/sda"
PART="1"
LOADER="/EFI/NixOS-boot/grubx64.efi"
LABEL="grub"

usage() {
  cat <<EOF
Usage: $0 [-d <disk>] [-p <part>] [-l <loader>] [-L <label>]
  -d <disk>   : disk holding the ESP        (default: $DISK)
  -p <part>   : ESP partition number        (default: $PART)
  -l <loader> : loader path within the ESP  (default: $LOADER)
  -L <label>  : boot entry label            (default: $LABEL)
EOF
  exit 1
}

while getopts ":d:p:l:L:h" opt; do
  case $opt in
    d) DISK="$OPTARG" ;;
    p) PART="$OPTARG" ;;
    l) LOADER="$OPTARG" ;;
    L) LABEL="$OPTARG" ;;
    *) usage ;;
  esac
done

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root" >&2
  exit 1
fi

echo "Creating UEFI boot entry:"
echo "  disk:   $DISK"
echo "  part:   $PART"
echo "  loader: $LOADER"
echo "  label:  $LABEL"
echo

efibootmgr --create \
  --disk "$DISK" \
  --part "$PART" \
  --loader "$LOADER" \
  --label "$LABEL" \
  --verbose
