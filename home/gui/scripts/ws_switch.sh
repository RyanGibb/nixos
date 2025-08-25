#!/usr/bin/env bash

NAME="$(eval "$1")" || exit

@wmmsg@ workspace \"$NAME\"

notify-send "$NAME" -t 500
