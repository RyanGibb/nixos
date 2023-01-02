#!/usr/bin/env bash

WALLPAPER_DIR=$HOME/pictures/wallpapers

WALLPAPER=$(ls $WALLPAPER_DIR | while read A ; do  echo -en "$A\x00icon\x1f$WALLPAPER_DIR/$A\n"; done | rofi -dmenu -p "$(basename "$(readlink -f $WALLPAPER_DIR/default)")") || exit 1

# for wofi:
#	WALLPAPER=$(ls $WALLPAPER_DIR | while read A ; do echo -en "img:$WALLPAPER_DIR/${A}:text:${A}\n"; done | wofi -d -I -p "$(basename "$(readlink -f $WALLPAPER_DIR/default)")") || exit 1I
# but very slow...
# from https://dotfiles.cloudninja.pw/scripts/wofipaper

ln -sf "$WALLPAPER_DIR/$WALLPAPER" $WALLPAPER_DIR/default || exit 1

@set_wallpaper@
