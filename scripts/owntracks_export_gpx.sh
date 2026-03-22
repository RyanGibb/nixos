#!/usr/bin/env sh
# Export a GPX trace from OwnTracks recorder on elephant
ssh elephant nix shell nixpkgs#owntracks-recorder -c ocat --user user --device pixel7a -S /var/lib/owntracks -F 2026-01-01 --format gpx > ~/pictures/trace.gpx
