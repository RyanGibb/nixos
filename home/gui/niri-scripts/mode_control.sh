#!/usr/bin/env bash
choice=$(printf 'b - backlight up
B - backlight down
= - backlight up 1%%
- - backlight down 1%%
d - dpms off
o - outputs on
D - disable focused output
t - touchpad dwt enable (unsupported)
T - touchpad dwt disable (unsupported)' | wofi -d -i -p 'control')
case "${choice:0:1}" in
  b) brightnessctl set 10%+ ;;
  B) brightnessctl set 10%- ;;
  =) brightnessctl set 1%+ ;;
  -) brightnessctl set 1%- ;;
  d) niri msg action power-off-monitors ;;
  o) niri msg action power-on-monitors ;;
  D)
    name=$(niri msg --json focused-output | jq -r .name)
    niri msg output "$name" off
    ;;
  t|T) notify-send "runtime input config not supported by niri" ;;
esac
[ -n "$choice" ] && notify-send "$choice"
