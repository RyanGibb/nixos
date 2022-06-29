#!/usr/bin/env bash

cd "$(dirname $0)"

dnssec-signzone -A -3 $(head -c 1000 /dev/random | sha1sum | cut -b 1-16) -N INCREMENT -o gibbr.org -t gibbr.org.zone

