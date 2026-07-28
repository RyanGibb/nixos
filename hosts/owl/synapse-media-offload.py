#!/usr/bin/env python3
"""Offload cold synapse media to garage S3, deleting each local copy only after
verifying the stored object byte-for-byte.

s3_media_upload's own --delete only checks that an object with the right key
exists, so a truncated or corrupt object would still let it drop the local
file. This runs `upload` without --delete, then compares each object's ETag
against a digest computed from the local file, removing it only on an exact
match. Nothing is ever downloaded to verify it. Anything that fails is left on
disk and retried next run.

S3 keys are exactly the path relative to the media store, so enumeration has to
match synapse's layout:
    local_content/<a>/<b>/<rest>                    (file)
    local_thumbnails/<a>/<b>/<rest>/<thumb>         (directory of files)
    remote_content/<origin>/<a>/<b>/<rest>          (file)
    remote_thumbnail/<origin>/<a>/<b>/<rest>/<thumb>
"""
import hashlib
import os
import re
import sqlite3
import subprocess
import sys

MEDIA_STORE = "/var/lib/matrix-synapse/media_store"
SECRET = "/run/agenix/synapse-s3-config.yml"
CACHE_DIR = os.environ.get("STATE_DIRECTORY", "/var/lib/synapse-media-offload")
S3UP = os.environ["S3_MEDIA_UPLOAD"]
AGE = os.environ.get("OFFLOAD_AGE", "90d")


def secret(key, default=None):
    m = re.search(rf"^\s*{key}:\s*(.+?)\s*$", open(SECRET).read(), re.M)
    return m.group(1).strip("\"'") if m else default


def homeserver_config():
    out = subprocess.run(
        ["systemctl", "show", "matrix-synapse", "-p", "ExecStart", "--value"],
        capture_output=True, text=True, check=True).stdout
    m = re.search(r"(/nix/store/\S+homeserver\.yaml)", out)
    if not m:
        sys.exit("could not locate synapse homeserver.yaml")
    return m.group(1)


def md5_path(path, chunk=1 << 20):
    h = hashlib.md5()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(chunk), b""):
            h.update(block)
    return h.hexdigest()


def etag_matches(path, etag):
    """Whether the local file reproduces the object's ETag, without downloading.

    Single-part objects use a plain MD5. Multipart ones use the MD5 of the
    concatenated part MD5s with a "-N" part count, which is reproducible
    locally if the part size matches; candidates are derived from the file size
    and part count. Returns False when it can't be reproduced, so the caller
    keeps the local copy rather than trusting it.
    """
    etag = etag.strip('"')
    if "-" not in etag:
        return md5_path(path) == etag

    want, _, parts = etag.partition("-")
    try:
        nparts = int(parts)
    except ValueError:
        return False
    size = os.path.getsize(path)
    if nparts < 1:
        return False

    mib = 1 << 20
    derived = -(-size // nparts)                      # ceil, the minimum viable size
    candidates = {8 * mib, 5 * mib, 15 * mib, 16 * mib, 64 * mib, 100 * mib,
                  -(-derived // mib) * mib}           # rounded up to a whole MiB
    for part_size in sorted(candidates):
        if part_size <= 0 or -(-size // part_size) != nparts:
            continue
        digests = []
        with open(path, "rb") as f:
            for block in iter(lambda: f.read(part_size), b""):
                digests.append(hashlib.md5(block).digest())
        if hashlib.md5(b"".join(digests)).hexdigest() == want:
            return True
    return False


def local_files(origin, fsid, m_type):
    """Every file synapse stores for one media id, relative to MEDIA_STORE.

    Mirrors s3_media_upload's to_path/to_thumbnail_dir/get_local_files: the
    local-vs-remote split comes from m_type, not from origin, and the S3 key is
    exactly this relative path.
    """
    a, b, rest = fsid[:2], fsid[2:4], fsid[4:]
    if m_type == "local":
        content = os.path.join("local_content", a, b, rest)
        thumbs = os.path.join("local_thumbnails", a, b, rest)
    elif m_type == "remote":
        content = os.path.join("remote_content", origin, a, b, rest)
        thumbs = os.path.join("remote_thumbnail", origin, a, b, rest)
    else:
        raise ValueError(f"unexpected media type {m_type!r}")
    out = []
    if os.path.isfile(os.path.join(MEDIA_STORE, content)):
        out.append(content)
    tdir = os.path.join(MEDIA_STORE, thumbs)
    if os.path.isdir(tdir):
        out += [os.path.join(thumbs, f) for f in sorted(os.listdir(tdir))
                if os.path.isfile(os.path.join(tdir, f))]
    return out


def main():
    bucket = secret("bucket", "matrix-media")
    endpoint = secret("endpoint_url")
    region = secret("region_name", "garage")
    akey, asec = secret("access_key_id"), secret("secret_access_key")
    if not all([endpoint, akey, asec]):
        sys.exit(f"missing endpoint_url/access_key_id/secret_access_key in {SECRET}")

    env = dict(os.environ, AWS_ACCESS_KEY_ID=akey,
               AWS_SECRET_ACCESS_KEY=asec, AWS_DEFAULT_REGION=region)
    os.makedirs(CACHE_DIR, exist_ok=True)
    os.chdir(CACHE_DIR)          # cache.db is incremental; keep cwd stable

    def run(*args):
        subprocess.run([S3UP, "--no-progress", *args], env=env, check=True)

    run("update-db", AGE, "--homeserver-config-path", homeserver_config())
    run("check-deleted", MEDIA_STORE)
    run("upload", MEDIA_STORE, bucket, "--endpoint-url", endpoint)

    import boto3
    s3 = boto3.client("s3", endpoint_url=endpoint, region_name=region,
                      aws_access_key_id=akey, aws_secret_access_key=asec)
    db = sqlite3.connect(os.path.join(CACHE_DIR, "cache.db"))
    rows = db.execute(
        "SELECT origin, filesystem_id, type FROM media WHERE NOT known_deleted"
    ).fetchall()

    ok = bad = absent = 0
    freed = 0
    for origin, fsid, m_type in rows:
        for rel in local_files(origin, fsid, m_type):
            local = os.path.join(MEDIA_STORE, rel)
            try:
                etag = s3.head_object(Bucket=bucket, Key=rel)["ETag"]
            except Exception as e:
                absent += 1
                print(f"  not in bucket, keeping: {rel} ({str(e)[:60]})")
                continue
            if not etag_matches(local, etag):
                bad += 1
                print(f"  ETAG MISMATCH, keeping: {rel}")
                continue
            size = os.path.getsize(local)
            os.remove(local)
            try:
                os.removedirs(os.path.dirname(local))
            except OSError:
                pass
            ok += 1
            freed += size

    print(f"verified and removed {ok} files ({freed / 1e9:.2f} GB); "
          f"{bad} mismatched, {absent} unretrievable")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
