#!/usr/bin/env bash

laptop_output=eDP-1

if grep -q closed /proc/acpi/button/lid/LID*/state; then
    @disable_output@
else
    @enable_output@
fi

