#!/usr/bin/env bash
set -euo pipefail

SRC="$HOME/pictures/darktable"
DST="/mnt/elephant/ryan/pictures"

if [ $# -lt 1 ]; then
	echo "Usage: $(basename "$0") <film-roll-dir> [film-roll-dir ...]"
	echo "Moves film roll directories from $SRC to $DST"
	echo "and updates darktable's library database."
	exit 1
fi

DB="$HOME/.config/darktable/library.db"
if [ ! -f "$DB" ]; then
	echo "Error: darktable library not found at $DB"
	exit 1
fi

for roll in "$@"; do
	src_path="$SRC/$roll"
	dst_path="$DST/$roll"

	if [ ! -d "$src_path" ]; then
		echo "Error: $src_path does not exist"
		exit 1
	fi

	if [ -e "$dst_path" ]; then
		echo "Error: $dst_path already exists"
		exit 1
	fi

	echo "Moving $src_path -> $dst_path"
	rsync -aP "$src_path/" "$dst_path/"

	echo "Updating darktable library..."
	sqlite3 "$DB" "UPDATE film_rolls SET folder = REPLACE(folder, '$src_path', '$dst_path') WHERE folder LIKE '$src_path%';"

	echo "Removing local copy..."
	rm -rf "$src_path"

	echo "Done: $roll"
done
