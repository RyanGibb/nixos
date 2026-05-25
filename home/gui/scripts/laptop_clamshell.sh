#!/usr/bin/env bash

# shellcheck disable=SC2034  # referenced by @enable_output@/@disable_output@ template substitutions
laptop_output=eDP-1

if grep -q closed /proc/acpi/button/lid/LID*/state; then
    @disable_output@
else
    @enable_output@
fi

