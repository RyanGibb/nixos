#!/usr/bin/env bash

dir=/etc/nixos/secrets
file=wireguard_key_"$(hostname)"
A
umask 077
chmod 700 "$dir"

wg genkey > "$dir/$file"
wg pubkey < "$dir/$file"

