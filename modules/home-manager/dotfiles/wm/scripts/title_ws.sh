#!/usr/bin/env bash

TITLE="$(eval $1)" || exit
@wmmsg@ rename workspace to \"$TITLE\"
