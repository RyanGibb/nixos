#!/usr/bin/env bash

PROMPT='Workspace name:'
yad --entry --text "$PROMPT" --entry-text="$(eval $1)"
