#!/usr/bin/env bash
choice=$(printf 'i - inhibit
d - dpms
l - lock
L - lock (no dpms)
s - suspend
S - suspend (long)' | wofi -d -i -p 'idle')
script_dir="$HOME/.config/sway/scripts"
case "${choice:0:1}" in
  i) "$script_dir/swayidle_inhibit.sh" ;;
  d) "$script_dir/swayidle_dpms.sh" ;;
  l) "$script_dir/swayidle_lock.sh" ;;
  L) "$script_dir/swayidle_lock_no_dpms.sh" ;;
  s) "$script_dir/swayidle_suspend.sh" ;;
  S) "$script_dir/swayidle_suspend_long.sh" ;;
esac
[ -n "$choice" ] && notify-send "$choice"
