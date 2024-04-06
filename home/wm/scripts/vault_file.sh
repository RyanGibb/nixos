#!/usr/bin/env bash

file="$(date '+%Y-%m-%d').md"
cd ~/projects/vault || exit
vim "$file"
