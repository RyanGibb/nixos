#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p "python3.withPackages(ps: with ps; [boto3 pyyaml])" -p postgresql
"""
Delete local-disk copies of synapse media uploaded by bridge appservice users.
The S3 copy on elephant is left intact, so synapse keeps serving via the
storage provider's read-fallback.

Default is dry-run; pass --execute to actually delete.
Pass --no-verify to skip the HeadObject safety check on every file (faster
but trusts the migration without verification).

Must run as root on owl (reads /run/agenix/synapse-s3-config.yml and
unlinks files in /var/lib/matrix-synapse/media_store).
"""
import argparse
import os
import shutil
import subprocess
import sys
import yaml
import boto3
from botocore.exceptions import ClientError

MEDIA_ROOT = "/var/lib/matrix-synapse/media_store"
SECRETS = "/run/agenix/synapse-s3-config.yml"


def split_media_id(media_id):
    return media_id[:2], media_id[2:4], media_id[4:]


def local_paths(media_id):
    aa, bb, rest = split_media_id(media_id)
    return (
        f"{MEDIA_ROOT}/local_content/{aa}/{bb}/{rest}",
        f"{MEDIA_ROOT}/local_thumbnails/{aa}/{bb}/{rest}",
    )


def s3_key(media_id):
    aa, bb, rest = split_media_id(media_id)
    return f"local_content/{aa}/{bb}/{rest}"


def dir_bytes(path):
    if not os.path.isdir(path):
        return 0
    total = 0
    for root, _, files in os.walk(path):
        for f in files:
            try:
                total += os.path.getsize(os.path.join(root, f))
            except OSError:
                pass
    return total


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--execute", action="store_true",
                   help="actually unlink files (default: dry-run)")
    p.add_argument("--no-verify", action="store_true",
                   help="skip HeadObject S3 presence check (faster, less safe)")
    args = p.parse_args()

    with open(SECRETS) as f:
        cfg = yaml.safe_load(f)
    pcfg = cfg["media_storage_providers"][0]["config"]
    s3 = boto3.client(
        "s3",
        endpoint_url=pcfg["endpoint_url"],
        region_name=pcfg["region_name"],
        aws_access_key_id=pcfg["access_key_id"],
        aws_secret_access_key=pcfg["secret_access_key"],
    )
    bucket = pcfg["bucket"]

    # Peer-auth: shell out to psql as the matrix-synapse user. Tab-separated,
    # ASCII record separator unlikely to collide with media_id chars.
    sql = """
        SELECT lmr.media_id, lmr.user_id, u.appservice_id
        FROM local_media_repository lmr
        JOIN users u ON u.name = lmr.user_id
        WHERE u.appservice_id IS NOT NULL
        ORDER BY lmr.media_id
    """
    out = subprocess.check_output(
        ["sudo", "-u", "matrix-synapse", "psql", "-h", "/run/postgresql",
         "-d", "matrix-synapse", "-t", "-A", "-F", "\t", "-c", sql],
        text=True,
    )
    rows = []
    for line in out.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) == 3:
            rows.append(tuple(parts))
    print(f"candidates from DB: {len(rows)}")

    deleted = 0
    bytes_freed = 0
    missing_local = 0
    missing_s3 = 0
    by_as = {}

    for media_id, user_id, asid in rows:
        content_path, thumb_dir = local_paths(media_id)

        if not os.path.exists(content_path) and not os.path.isdir(thumb_dir):
            missing_local += 1
            continue

        if not args.no_verify:
            try:
                s3.head_object(Bucket=bucket, Key=s3_key(media_id))
            except ClientError as e:
                if e.response.get("Error", {}).get("Code") == "404":
                    missing_s3 += 1
                    continue
                raise

        size = 0
        if os.path.exists(content_path):
            try:
                size += os.path.getsize(content_path)
            except OSError:
                pass
        size += dir_bytes(thumb_dir)

        bytes_freed += size
        deleted += 1
        by_as[asid] = by_as.get(asid, 0) + size

        if args.execute:
            if os.path.exists(content_path):
                try:
                    os.unlink(content_path)
                except OSError as e:
                    print(f"  WARN: unlink {content_path}: {e}", file=sys.stderr)
            if os.path.isdir(thumb_dir):
                try:
                    shutil.rmtree(thumb_dir)
                except OSError as e:
                    print(f"  WARN: rmtree {thumb_dir}: {e}", file=sys.stderr)

        if deleted % 500 == 0:
            print(f"  ...{deleted} done, {bytes_freed / 2**30:.2f} GiB freed")

    action = "DELETED" if args.execute else "WOULD DELETE"
    print()
    print(f"{action}: {deleted} files, {bytes_freed / 2**30:.2f} GiB")
    print(f"missing on local disk (already gone): {missing_local}")
    if not args.no_verify:
        print(f"missing from S3 (skipped, NOT deleted locally): {missing_s3}")
    print()
    print("by appservice:")
    for asid in sorted(by_as):
        print(f"  {asid:<20} {by_as[asid] / 2**30:>7.2f} GiB")


if __name__ == "__main__":
    main()
