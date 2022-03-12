#!/usr/bin/env bash

playerctl play-pause -p "$(playerctl -l | sed -n "$1p")"

