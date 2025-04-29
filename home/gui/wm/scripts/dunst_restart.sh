#!/usr/bin/env bash

while true; do
        swaymsg -t subscribe '["output"]';
        sleep 3;
        pkill dunst
done
