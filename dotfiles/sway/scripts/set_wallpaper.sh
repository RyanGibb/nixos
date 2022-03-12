#!/usr/bin/env bash

WALLPAPER_DIR=~/pictures/wallpapers

WALLPAPER="$1"

echo $WALLPAPER
ln -sf "$WALLPAPER" $WALLPAPER_DIR/default || exit 1

swaymsg "output * bg $WALLPAPER_DIR/default fill"
