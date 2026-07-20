#!/usr/bin/env python3
"""Generate cores.json (platform -> core/ext/src) from launch.tsv.

generate.sh already resolves every play:// path to its libretro core, inner
Internet-Archive extension and fully-qualified source URL (with the real inner
zip prefix discovered by listing each archive) and writes them, one TAB-
separated row per path, to launch.tsv:

    KEY<TAB>core<TAB>ext<TAB>src

That is the single source of truth the desktop launchers (retroarch.sh /
retroarch.ps1) consume. We turn the same table into the ordered JSON array
intent.js (Android -> native RetroArch via intent://) fetches, so every
launcher does the identical first-substring-match lookup and cores.json can
never drift from platforms.csv again.

Reading launch.tsv (rather than re-parsing the bash `case` block) is lossless:
MAME autoboot commands contain both " and \n, which broke the old regex-based
retroarch.sh parser and left cores.json with truncated core strings.

Only keys that start with "/" are emitted — the Android intent path handles the
"/platform/folder/" ROM entries, not the fantasy pseudo-platforms (TIC-80/,
PICO-8/, ...) whose keys have no leading slash. This matches the historical
gen_cores.py behaviour.

Usage: gen_cores.py /path/to/launch.tsv > cores.json
"""
import json
import sys


def parse(path):
    out = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line:
                continue
            parts = line.split("\t")
            pattern = parts[0]
            if not pattern.startswith("/"):
                continue
            entry = {"pattern": pattern, "core": parts[1] if len(parts) > 1 else ""}
            ext = parts[2] if len(parts) > 2 else ""
            src = parts[3] if len(parts) > 3 else ""
            if ext:
                entry["ext"] = ext
            if src:
                entry["src"] = src
            out.append(entry)
    return out


if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else "launch.tsv"
    entries = parse(src)
    json.dump(entries, sys.stdout, ensure_ascii=False, indent=1)
    print()
    print(f"// {len(entries)} entries", file=sys.stderr)
