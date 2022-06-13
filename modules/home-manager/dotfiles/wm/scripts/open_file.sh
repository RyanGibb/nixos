#!/bin/sh

FILE="$(fzf)" || exit 1
xdg-open "$FILE" & disown

zsh -i

