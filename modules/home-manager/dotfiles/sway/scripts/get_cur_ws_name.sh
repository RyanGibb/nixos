#!/usr/bin/env bash

swaymsg -t get_workspaces\
  | jq '.[] | select(.focused==true).name'\
  | cut -d"\"" -f2
