#!/usr/bin/env bash

title="$(yad --entry --text=Title:)" || exit
file="$(date '+%Y-%m-%d') $title.md"
cd ~/projects/vault || exit
vim "$file"
