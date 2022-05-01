#!/usr/bin/env bash

PROMPT='Workspace name:'
zenity --entry --text "$PROMPT" --entry-text="$(eval $1)"
