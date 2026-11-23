#!/usr/bin/env python3
# Fallback lister for archive:item/path.zip ROM collections.
# Reads only the ZIP central directory over authenticated HTTP range requests
# (works for restricted IA items) and prints inner file names with the top-level
# directory prefix stripped -- byte-for-byte the same output generate.sh's
# `unzip -l | awk` step produces from the rclone mount.
import sys, os, re, struct, time, urllib.request, urllib.error

def rclone_auth():
    for p in (os.path.expanduser("~/.config/rclone/rclone.conf"), "rclone.conf"):
        if os.path.exists(p):
            key = sec = None
            in_archive = False
            for line in open(p):
                line = line.strip()
                if line.startswith("["):
                    in_archive = (line == "[archive]")
                elif in_archive and "=" in line:
                    k, v = (x.strip() for x in line.split("=", 1))
                    if k == "access_key_id": key = v
                    elif k == "secret_access_key": sec = v
            if key and sec:
                return f"LOW {key}:{sec}"
    return None

def http(url, auth, rng=None, method="GET", tries=6):
    h = {}
    if auth: h["Authorization"] = auth
    if rng: h["Range"] = f"bytes={rng[0]}-{rng[1]}"
    last = None
    for attempt in range(tries):
        try:
            return urllib.request.urlopen(
                urllib.request.Request(url, headers=h, method=method), timeout=120)
        except (urllib.error.HTTPError, urllib.error.URLError, OSError) as e:
            # IA intermittently 500s / drops the connection on the redirect to a
            # storage node -- retry with backoff before giving up.
            code = getattr(e, "code", None)
            if code is not None and code not in (500, 502, 503, 504, 429):
                raise
            last = e
            time.sleep(2 * (attempt + 1))
    raise last

def central_names(url, auth):
    n = int(http(url, auth, method="HEAD").headers["Content-Length"])
    # EOCD is within the last 64 KiB + comment; grab a generous tail.
    tail = http(url, auth, (max(0, n - 70000), n - 1)).read()
    idx = tail.rfind(b"PK\x05\x06")
    if idx < 0:
        raise RuntimeError("no EOCD")
    total, cd_size, cd_off = struct.unpack("<HII", tail[idx + 10:idx + 20])
    if cd_off == 0xFFFFFFFF or total == 0xFFFF:  # ZIP64
        z = tail.rfind(b"PK\x06\x07")            # ZIP64 EOCD locator
        if z < 0:
            raise RuntimeError("no ZIP64 locator")
        z64_off = struct.unpack("<Q", tail[z + 8:z + 16])[0]
        z64 = http(url, auth, (z64_off, z64_off + 56 - 1)).read()
        cd_size, cd_off = struct.unpack("<QQ", z64[40:56])
    cd = http(url, auth, (cd_off, cd_off + cd_size - 1)).read()
    names, i = [], 0
    while i + 46 <= len(cd) and cd[i:i + 4] == b"PK\x01\x02":
        nlen, elen, clen = struct.unpack("<HHH", cd[i + 28:i + 34])
        names.append(cd[i + 46:i + 46 + nlen].decode("utf-8", "replace"))
        i += 46 + nlen + elen + clen
    return names

def main():
    path = sys.argv[1]                 # archive:item/sub/file.zip
    out_txt = sys.argv[2]
    out_prefix = sys.argv[3] if len(sys.argv) > 3 else None
    aftercolon = path.split(":", 1)[1]
    item = aftercolon.split("/", 1)[0]
    sub = aftercolon[len(item):].lstrip("/")
    url = f"https://archive.org/download/{item}/" + "/".join(
        urllib.request.quote(p) for p in sub.split("/"))
    names = central_names(url, rclone_auth())
    prefix_re = re.compile(r"^[a-z0-9_]+/")
    wrote_prefix = False
    lines = []
    for name in names:
        if not wrote_prefix and out_prefix:
            m = prefix_re.match(name)
            with open(out_prefix, "w") as f:
                f.write((m.group(0) if m else "") + "\n")
            wrote_prefix = True
        stripped = prefix_re.sub("", name, count=1)
        if stripped and not stripped.endswith("/"):
            lines.append(stripped)
    with open(out_txt, "w") as f:
        f.write("\n".join(lines) + ("\n" if lines else ""))
    sys.stderr.write(f"{path}: {len(lines)} entries\n")

if __name__ == "__main__":
    main()
