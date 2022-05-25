#!/usr/bin/env bash

TITLE="$(eval $1)" || exit
swaymsg rename workspace to \"$TITLE\"
