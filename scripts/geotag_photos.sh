#!/usr/bin/env sh
# Geotag JPG photos using a GPX trace
exiftool *.JPG -geotag ~/pictures/trace.gpx
