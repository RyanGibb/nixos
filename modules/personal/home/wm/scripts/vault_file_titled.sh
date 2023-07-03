#!/usr/bin/env bash

title="$(zenity --entry --text=Title:)" || exit
file="$title.md"
cd ~/projects/vault || exit
$EDITOR "$file"
