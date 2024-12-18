#!/usr/bin/env bash

echo "$(\
    @wmmsg@ -t get_tree\
    | jq -r '..
        | select(.pid? and .visible?)
        | .rect
        | "\(.x),\(.y) \(.width)x\(.height)"'\
    | slurp
)"
