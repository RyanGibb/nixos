#!/usr/bin/env bash

WALLPAPER_DIR=~/pictures/wallpapers

WALLPAPER=$(ls $WALLPAPER_DIR | wofi -d -p "$(basename "$(readlink -f $WALLPAPER_DIR/default)")") || exit 1

ln -sf "$WALLPAPER_DIR/$WALLPAPER" $WALLPAPER_DIR/default || exit 1

swaymsg "output * bg $WALLPAPER_DIR/default fill"
