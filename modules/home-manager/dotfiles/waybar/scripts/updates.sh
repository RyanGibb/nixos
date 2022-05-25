#!/usr/bin/env bash

arch_updates="$(checkupdates)"
arch_updates_rc="$?"
if [[ "$arch_updates_rc" == "1" ]]; then exit 1; fi

aur_updates="$(yay -Qua)" || exit 1

if [[ "$arch_updates_rc" == "2" ]]; then
	num_arch_updates=0
else
	num_arch_updates="$(echo "$arch_updates" | wc -l)"
fi
if [[ "$aur_updates" == "" ]]; then
	num_aur_updates=0
else
	num_aur_updates="$(echo "$aur_updates" | wc -l)"
fi

echo "$num_arch_updates$num_aur_updates"
