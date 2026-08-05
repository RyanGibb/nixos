#!/usr/bin/env bash
choice=$(printf 'lock\nexit\nsuspend-then-hibernate\nsuspend\nhibernate\nreboot\npoweroff\nuefi/bios' | wofi -d -i -p 'system')
case "$choice" in
  lock)                   loginctl lock-session ;;
  exit)                   niri msg action quit ;;
  suspend-then-hibernate) systemctl suspend-then-hibernate ;;
  suspend)                systemctl suspend ;;
  hibernate)              systemctl hibernate ;;
  reboot)                 systemctl reboot ;;
  poweroff)               systemctl poweroff -i ;;
  uefi/bios)              systemctl reboot --firmware-setup ;;
esac
[ -n "$choice" ] && notify-send "$choice"
