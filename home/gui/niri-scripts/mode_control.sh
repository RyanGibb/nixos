#!/usr/bin/env bash
choice=$(printf 'backlight-up\nbacklight-down\nbacklight-up-1%%\nbacklight-down-1%%\ndpms-off\noutputs-on\noutput-off-focused\ntouchpad-dwt-enable\ntouchpad-dwt-disable' | wofi -d -i -p 'control')
case "$choice" in
  backlight-up)          brightnessctl set 10%+ ;;
  backlight-down)        brightnessctl set 10%- ;;
  "backlight-up-1%")     brightnessctl set 1%+ ;;
  "backlight-down-1%")   brightnessctl set 1%- ;;
  dpms-off)              niri msg action power-off-monitors ;;
  outputs-on)            niri msg action power-on-monitors ;;
  output-off-focused)
    name=$(niri msg --json focused-output | jq -r .name)
    niri msg output "$name" off
    ;;
  touchpad-dwt-enable)   notify-send "runtime input config not supported by niri" ;;
  touchpad-dwt-disable)  notify-send "runtime input config not supported by niri" ;;
esac
[ -n "$choice" ] && notify-send "$choice"
