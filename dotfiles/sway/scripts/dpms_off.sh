#!/usr/bin/env bash

swayidle -w \
  timeout 1 'swaymsg "output * dpms off"' \
  resume 'swaymsg "output * enable"; swaymsg "output * dpms on "; pkill -nx swayidle'

