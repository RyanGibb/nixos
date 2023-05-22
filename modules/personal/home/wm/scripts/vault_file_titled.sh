#!/usr/bin/env bash

title="$(zenity --entry --text=Title:)" || exit
file="$(date '+%Y-%m-%d') $title.md"
cd ~/projects/vault || exit
vim "$file"
