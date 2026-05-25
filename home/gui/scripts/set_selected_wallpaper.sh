#!/usr/bin/env bash

WALLPAPER=$(find "$WALLPAPER_DIR" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort | while read -r A ; do printf '%s\0icon\x1f%s/%s\n' "$A" "$WALLPAPER_DIR" "$A"; done | rofi -dmenu -p "$(basename "$(readlink -f "$HOME/.cache/wallpaper")")") || exit 1

# for wofi:
#      WALLPAPER=$(ls $WALLPAPER_DIR | while read A ; do echo -en "img:$WALLPAPER_DIR/${A}:text:${A}\n"; done | wofi -d -I -p "$(basename "$(readlink -f $HOME/.cache/wallpaper)")") || exit 1I
# but very slow...
# from https://dotfiles.cloudninja.pw/scripts/wofipaper

ln -sf "$WALLPAPER_DIR/$WALLPAPER" "$HOME/.cache/wallpaper" || exit 1

@set_wallpaper@
