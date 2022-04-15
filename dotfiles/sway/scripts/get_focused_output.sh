#!/usr/bin/env bash

swaymsg -t get_tree | jq -r '.nodes[] | select([recurse(.nodes[]?, .floating_nodes[]?) | .focused] | any) | .name'
