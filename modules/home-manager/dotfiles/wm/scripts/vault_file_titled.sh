#!/bin/sh

title="$(zenity --entry --text=Title:)" || exit
file="$(date '+%Y-%m-%d %H.%M') $title.md"
cd ~/projects/vault || exit
vim "$file"
