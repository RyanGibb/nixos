#!/usr/bin/env bash

FILE="$(fzf)" || exit 1
xdg-open "$FILE" & disown

zsh -i

