#!/usr/bin/env bash

file="$(date '+%Y-%m-%d %H.%M').md"
cd ~/projects/vault || exit
vim "$file"
