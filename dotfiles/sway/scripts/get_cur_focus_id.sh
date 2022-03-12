#!/usr/bin/env bash

swaymsg -t get_tree \
  | jq -r 'recurse(.nodes[], .floating_nodes[];.nodes!=null) | select(.focused==true).id'
