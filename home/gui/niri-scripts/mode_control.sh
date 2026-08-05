#!/usr/bin/env bash
choice=$(printf 'd - dpms off
o - outputs on
D - disable focused output' | wofi -d -i -p 'control')
case "${choice:0:1}" in
  d) niri msg action power-off-monitors ;;
  o) niri msg action power-on-monitors ;;
  D)
    name=$(niri msg --json focused-output | jq -r .name)
    niri msg output "$name" off
    ;;
esac
[ -n "$choice" ] && notify-send "$choice"
