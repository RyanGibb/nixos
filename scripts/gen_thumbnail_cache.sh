#!/usr/bin/env bash
set -euo pipefail

# Generating thumbnails locally reads whole RAWs over NFS (~36 MB/image);
# doing it on elephant where the files are local and shipping back the
# mipmaps (~1.4 MB/image) is roughly 20x less traffic.

REMOTE="${REMOTE:-root@elephant}"
REMOTE_BASE="${REMOTE_BASE:-/home/ryan/dtgen}"
REMOTE_PICTURES="${REMOTE_PICTURES:-/tank/ryan}"
LOCAL_MOUNT="${LOCAL_MOUNT:-/mnt/elephant/ryan}"
MAXMIP="${MAXMIP:-5}"
JOBS="${JOBS:-0}"

CFG="$HOME/.config/darktable"
DB="$CFG/library.db"

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
	echo "Usage: $(basename "$0") [film-roll-dir ...]"
	echo
	echo "Generates darktable thumbnails on $REMOTE and copies them back."
	echo "With no arguments, does the entire library."
	echo
	echo "Env: REMOTE MAXMIP JOBS"
	exit 0
fi

if pgrep -x darktable >/dev/null || pgrep -f darktable-generate-cache >/dev/null; then
	echo "Error: darktable is running; quit it first (it holds the library lock)"
	exit 1
fi

for cmd in rsync ssh sha1sum; do
	command -v "$cmd" >/dev/null || { echo "Error: $cmd not found"; exit 1; }
done

if command -v sqlite3 >/dev/null; then
	SQLITE=(sqlite3)
else
	SQLITE=(nix shell nixpkgs#sqlite -c sqlite3)
fi

[ -f "$DB" ] || { echo "Error: darktable library not found at $DB"; exit 1; }

DT_BIN="$(readlink -f "$(command -v darktable)" 2>/dev/null || true)"
[ -n "$DT_BIN" ] || { echo "Error: darktable not in PATH"; exit 1; }
DT_STORE="${DT_BIN%/bin/darktable}"

# darktable derives the cache directory name from the library path
HASH="$(printf '%s' "$DB" | sha1sum | cut -d' ' -f1)"
CACHE="$HOME/.cache/darktable/mipmaps-$HASH.d"

if [ $# -gt 0 ]; then
	where=""
	for roll in "$@"; do
		esc="${roll//\'/\'\'}"
		where="${where:+$where OR }folder LIKE '%/$esc'"
	done
	WHERE="film_id IN (SELECT id FROM film_rolls WHERE $where)"
else
	WHERE="1=1"
fi

COUNT="$("${SQLITE[@]}" "$DB" "SELECT COUNT(*) FROM images WHERE $WHERE;")"
[ "$COUNT" -gt 0 ] || { echo "Error: no images matched"; exit 1; }

if [ "$JOBS" -le 0 ]; then
	JOBS="$(ssh "$REMOTE" nproc)"
	JOBS=$((JOBS - 1))
	[ "$JOBS" -ge 1 ] || JOBS=1
fi
[ "$JOBS" -le "$COUNT" ] || JOBS="$COUNT"

echo "Images: $COUNT   jobs: $JOBS   max-mip: $MAXMIP"

# split into JOBS contiguous id ranges of equal image count
RANGES=()
lo="$("${SQLITE[@]}" "$DB" "SELECT MIN(id) FROM images WHERE $WHERE;")"
for ((j = 1; j <= JOBS; j++)); do
	if [ "$j" -eq "$JOBS" ]; then
		hi="$("${SQLITE[@]}" "$DB" "SELECT MAX(id) FROM images WHERE $WHERE;")"
	else
		off=$((COUNT * j / JOBS))
		hi="$("${SQLITE[@]}" "$DB" \
			"SELECT id FROM images WHERE $WHERE ORDER BY id LIMIT 1 OFFSET $((off - 1));")"
	fi
	RANGES+=("$lo:$hi")
	lo=$((hi + 1))
done

echo "Preparing $REMOTE ..."
ssh "$REMOTE" "
	set -e
	nix copy --from https://cache.nixos.org '$DT_STORE' >/dev/null 2>&1 || true
	[ -x '$DT_STORE/bin/darktable-generate-cache' ] || { echo 'Error: darktable not available on remote'; exit 1; }
	mkdir -p '$(dirname "$LOCAL_MOUNT")'
	ln -sfn '$REMOTE_PICTURES' '$LOCAL_MOUNT'
	rm -rf '$REMOTE_BASE'
	mkdir -p '$REMOTE_BASE/cfg'
"
scp -q "$DB" "$CFG/data.db" "$CFG/darktablerc" "$REMOTE:$REMOTE_BASE/cfg/"

ssh "$REMOTE" "cat > '$REMOTE_BASE/run.sh'" <<'RUNNER'
#!/usr/bin/env bash
set -euo pipefail
BASE="$1"; DT_STORE="$2"; MAXMIP="$3"; shift 3
i=0
for range in "$@"; do
	i=$((i + 1))
	mkdir -p "$BASE/h$i/.config/darktable"
	cp "$BASE"/cfg/* "$BASE/h$i/.config/darktable/"
	HOME="$BASE/h$i" "$DT_STORE/bin/darktable-generate-cache" \
		--min-mip 0 --max-mip "$MAXMIP" \
		--min-imgid "${range%%:*}" --max-imgid "${range##*:}" \
		> "$BASE/h$i.log" 2>&1 &
done
wait
mkdir -p "$BASE/merged"
for d in "$BASE"/h*/.cache/darktable/mipmaps-*.d; do
	[ -d "$d" ] && rsync -a "$d/" "$BASE/merged/"
done
touch "$BASE/ALL.done"
RUNNER

echo "Generating on $REMOTE ..."
ssh "$REMOTE" "setsid nohup bash '$REMOTE_BASE/run.sh' '$REMOTE_BASE' '$DT_STORE' '$MAXMIP' ${RANGES[*]} >/dev/null 2>&1 < /dev/null &"

while ! ssh "$REMOTE" "test -f '$REMOTE_BASE/ALL.done'"; do
	if ! ssh "$REMOTE" "pgrep -f darktable-generate-cache >/dev/null"; then
		sleep 5
		ssh "$REMOTE" "test -f '$REMOTE_BASE/ALL.done'" || {
			echo "Error: generation stopped early; see $REMOTE:$REMOTE_BASE/h*.log"
			exit 1
		}
		break
	fi
	done_n="$(ssh "$REMOTE" "cat '$REMOTE_BASE'/h*.log 2>/dev/null \
		| grep -o 'image [0-9]*/' | sed 's|image ||;s|/||' | awk '{s+=\$1} END {print s+0}'")"
	printf '\r  %s/%s images' "$done_n" "$COUNT"
	sleep 20
done
printf '\r  %s/%s images\n' "$COUNT" "$COUNT"

# smallest levels first so the lighttable grid is usable before the big ones land
echo "Copying cache back ..."
mkdir -p "$CACHE"
for ((l = 0; l <= MAXMIP; l++)); do
	ssh "$REMOTE" "test -d '$REMOTE_BASE/merged/$l'" || continue
	mkdir -p "$CACHE/$l"
	rsync -a --info=progress2 "$REMOTE:$REMOTE_BASE/merged/$l/" "$CACHE/$l/"
	echo "  level $l: $(ls "$CACHE/$l" | wc -l) files"
done

ssh "$REMOTE" "rm -rf '$REMOTE_BASE'"
echo "Done. Cache at $CACHE"
