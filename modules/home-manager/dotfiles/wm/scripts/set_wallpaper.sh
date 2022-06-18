#!/usr/bin/env bash

WALLPAPER_DIR=~/pictures/wallpapers

WALLPAPER="$1"

echo $WALLPAPER
ln -sf "$WALLPAPER" $WALLPAPER_DIR/default || exit 1

@set_wallpaper@
