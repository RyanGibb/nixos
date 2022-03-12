#!/usr/bin/env bash

NAME=$($(dirname "$0")/select_ws.sh) || exit

swaymsg workspace \"$NAME\"
