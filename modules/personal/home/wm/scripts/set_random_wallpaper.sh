#!/usr/bin/env bash

WALLPAPER_DIR=~/pictures/wallpapers

ln -sf "$(find $WALLPAPER_DIR -type f | sort -R | tail -1)" $WALLPAPER_DIR/default

@set_wallpaper@
