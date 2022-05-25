#!/usr/bin/env bash

pgrep -f -a swayidle | grep bash | sed -e 's/\(.*\)swayidle_\(.*\)\.sh/\2/'
