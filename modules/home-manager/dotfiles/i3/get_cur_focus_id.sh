#!/usr/bin/env bash
i3-msg -t get_tree \
  | jq -r 'recurse(.nodes[];.nodes!=null) | select(.focused==true).id'