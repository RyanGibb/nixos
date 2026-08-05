#!/usr/bin/env bash
choice=$(printf 'l - lock\ne - exit
s - suspend and then hibernate
S - suspend
h - hibernate
r - reboot
p - poweroff
u - uefi/bios' | wofi -d -i -p 'system')
case "${choice:0:1}" in
  l) loginctl lock-session ;;
  e) niri msg action quit ;;
  s) systemctl suspend-then-hibernate ;;
  S) systemctl suspend ;;
  h) systemctl hibernate ;;
  r) systemctl reboot ;;
  p) systemctl poweroff -i ;;
  u) systemctl reboot --firmware-setup ;;
esac
[ -n "$choice" ] && notify-send "$choice"
