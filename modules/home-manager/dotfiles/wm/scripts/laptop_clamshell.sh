#!/usr/bin/env bash

if grep -q open /proc/acpi/button/lid/LID0/state; then
    @wmmsg@ output $1 enable
else
    @wmmsg@ output $1 disable
fi

