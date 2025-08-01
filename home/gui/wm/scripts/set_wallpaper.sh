#!/usr/bin/env bash

WALLPAPER="$1"

echo $WALLPAPER
ln -sf "$WALLPAPER" $HOME/.cache/wallpaper || exit 1

@set_wallpaper@
