#!/usr/bin/env bash
choice=$(printf 'inhibit\ndpms\nlock\nlock-no-dpms\nsuspend\nsuspend-long' | wofi -d -i -p 'idle')
script_dir="$HOME/.config/sway/scripts"
case "$choice" in
  inhibit)      "$script_dir/swayidle_inhibit.sh" ;;
  dpms)         "$script_dir/swayidle_dpms.sh" ;;
  lock)         "$script_dir/swayidle_lock.sh" ;;
  lock-no-dpms) "$script_dir/swayidle_lock_no_dpms.sh" ;;
  suspend)      "$script_dir/swayidle_suspend.sh" ;;
  suspend-long) "$script_dir/swayidle_suspend_long.sh" ;;
esac
[ -n "$choice" ] && notify-send "$choice"
