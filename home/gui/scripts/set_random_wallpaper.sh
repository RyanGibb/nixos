#!/usr/bin/env bash

ln -sf "$(find $WALLPAPER_DIR -type f | sort -R | tail -1)" $HOME/.cache/wallpaper

@set_wallpaper@
