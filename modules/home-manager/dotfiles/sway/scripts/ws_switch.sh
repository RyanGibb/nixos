#!/usr/bin/env bash

NAME="$(eval "$1")" || exit

swaymsg workspace \"$NAME\"
