#!/usr/bin/env bash

WALLPAPER_DIR=~/pictures/wallpapers

WALLPAPER=$(ls $WALLPAPER_DIR | @dmenu@ "$(basename "$(readlink -f $WALLPAPER_DIR/default)")") || exit 1

ln -sf "$WALLPAPER_DIR/$WALLPAPER" $WALLPAPER_DIR/default || exit 1

@set_wallpaper@
