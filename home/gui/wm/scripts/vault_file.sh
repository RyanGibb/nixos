#!/usr/bin/env bash

file="$(date '+%Y-%m-%d').md"
cd ~/vault || exit
vim "$file"
