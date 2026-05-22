#!/usr/bin/env bash
# Migrate Synapse media from owl's local disk to garage on elephant.
#
# Run on owl as root. Safe to re-run — cache.db is incremental and the
# upload step skips objects already in the bucket.
#
# Phases:
#   1. update-db: build sqlite cache of all media not accessed in last 1s
#      (effectively: everything in synapse's DB).
#   2. check-deleted: mark cache entries whose file is missing on disk.
#   3. upload (no --delete): push everything to s3. Verify object count.
#   4. (manual, after verifying) re-run with --delete to reclaim disk.

set -euo pipefail

# Resolve paths
S3UP=$(nix eval --raw nixpkgs#matrix-synapse-plugins.matrix-synapse-s3-storage-provider.outPath)/bin/s3_media_upload
HSCONF=$(systemctl show matrix-synapse -p ExecStart --value | grep -oE '/nix/store/[^ ]+homeserver.yaml')
SECRETS=/run/agenix/synapse-s3-config.yml
MEDIA=/var/lib/matrix-synapse/media_store
BUCKET=matrix-media
ENDPOINT=http://100.64.0.9:3900
WORKDIR=/var/lib/synapse-s3-migration

echo "s3_media_upload : $S3UP"
echo "homeserver.yaml : $HSCONF"
echo "media store     : $MEDIA"
echo "bucket          : $BUCKET @ $ENDPOINT"
echo "workdir         : $WORKDIR"
echo

# Extract AWS creds from the agenix config (mode 440 matrix-synapse:matrix-synapse,
# so we run the extraction as that user)
AWS_ACCESS_KEY_ID=$(sudo -u matrix-synapse grep -E '^\s*access_key_id:' "$SECRETS" | awk '{print $2}')
AWS_SECRET_ACCESS_KEY=$(sudo -u matrix-synapse grep -E '^\s*secret_access_key:' "$SECRETS" | awk '{print $2}')

if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "ERROR: failed to extract AWS creds from $SECRETS" >&2
  exit 1
fi

# Prep workdir (matrix-synapse needs write access for cache.db)
mkdir -p "$WORKDIR"
chown matrix-synapse:matrix-synapse "$WORKDIR"

# Write a database.yaml the script will prefer over homeserver.yaml.
# Synapse on owl uses unix-socket peer auth (no password), but the script's
# homeserver.yaml parser requires a password field. database.yaml takes the
# preferred code path that passes kwargs directly to psycopg2.connect, which
# is happy with no password when the host is a unix socket.
cat > "$WORKDIR/database.yaml" <<'YAML'
postgres:
  user: matrix-synapse
  database: matrix-synapse
  host: /run/postgresql
YAML
chown matrix-synapse:matrix-synapse "$WORKDIR/database.yaml"

run_as_synapse() {
  cd "$WORKDIR"
  # AWS_DEFAULT_REGION must match garage's s3_region — otherwise SigV4 scope
  # mismatch → 400 on every request. The plugin (running inside synapse) sets
  # this via the config file's region_name; s3_media_upload doesn't read it.
  sudo -u matrix-synapse \
    AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    AWS_DEFAULT_REGION=garage \
    "$@"
}

echo "=== phase 1: update-db (sync DB rows into local cache) ==="
run_as_synapse "$S3UP" update-db 1s --homeserver-config-path "$HSCONF"

echo
echo "=== phase 2: check-deleted (mark missing-on-disk entries) ==="
run_as_synapse "$S3UP" check-deleted "$MEDIA"

echo
echo "=== phase 3: upload to s3 (NO --delete) ==="
run_as_synapse "$S3UP" upload "$MEDIA" "$BUCKET" --endpoint-url "$ENDPOINT"

echo
echo "=== done. verify in garage: ==="
echo "  ssh root@elephant 'garage bucket info $BUCKET'"
echo
echo "If Objects looks right, reclaim disk with:"
echo "  cd $WORKDIR && sudo -u matrix-synapse \\"
echo "    AWS_ACCESS_KEY_ID=… AWS_SECRET_ACCESS_KEY=… \\"
echo "    $S3UP upload $MEDIA $BUCKET --endpoint-url $ENDPOINT --delete"
