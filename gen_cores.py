#!/usr/bin/env python3
"""Generate cores.json (platform -> core/src/ext) from retroarch.sh.

The desktop launcher (wizzardsk.github.io/retroarch.sh) maps a play:// path to a
libretro core, an Internet-Archive source URL and (optionally) an inner extension
via one big bash `case` block. We parse that block into an ordered JSON array so
intent.js (Android -> native RetroArch via intent://) can do the exact same
first-substring-match lookup. Re-run when the case block changes.

Usage: gen_cores.py /path/to/retroarch.sh > cores.json
"""
import json
import re
import sys

LINE = re.compile(r'^\s*\*"(/[^"]*?)"\*\)\s*(.*?);;\s*$')
KV = re.compile(r'(core|src|ext)="([^"]*)"')


def parse(path):
    out = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            m = LINE.match(line)
            if not m:
                continue
            pattern, body = m.group(1), m.group(2)
            entry = {"pattern": pattern}
            for k, v in KV.findall(body):
                entry[k] = v
            out.append(entry)
    return out


if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else "retroarch.sh"
    entries = parse(src)
    json.dump(entries, sys.stdout, ensure_ascii=False, indent=1)
    print()
    print(f"// {len(entries)} entries", file=sys.stderr)
