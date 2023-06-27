#!/usr/bin/env bash

file="journals/$(date '+%Y_%m_%d').md"
cd ~/projects/vault || exit
$EDITOR "$file"
