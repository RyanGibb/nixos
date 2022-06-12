#!/usr/bin/env bash

max="$(cat /sys/class/backlight/*/max_brightness | cut -d " " -f 1)"
brightness="$(cat /sys/class/backlight/*/brightness | cut -d " " -f 1)"

echo $((brightness * 100 / max))
