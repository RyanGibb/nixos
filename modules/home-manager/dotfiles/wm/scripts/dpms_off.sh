#!/usr/bin/env bash

swayidle -w \
  timeout 1 '@wmmsg@ "output * dpms off"' \
  resume '@wmmsg@ "output * enable"; @wmmsg@ "output * dpms on "; pkill -nx swayidle'

