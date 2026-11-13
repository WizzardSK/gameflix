#!/usr/bin/env python3
# Writes mame_renames.tsv: for each of the site's older MAME lists, the sets
# MAME renamed since that list's version and the name each has now. The snaps
# in WizzardSK/MAME are named after today's sets, so a list from MAME 0.78
# would look for "blkhearj.png" where the snap is "blkheartj.png".
#
# The input is AntoPISA's allMAMErenamed.txt (progettosnaps renameSET, every
# rename from MAME 0.1 on, with the machine's ID and the version):
#   python3 gen_mame_renames.py allMAMErenamed.txt > mame_renames.tsv
# Columns: list folder, set name in that list, set name now.
#
# A rename belongs to a machine (its ID); a name can pass from one machine to
# another (1942 was renamed 1942a in 0.33b7 and 1942b became 1942 in 0.124u4),
# so the first rename of the name after the list's version picks the machine,
# and the machine's last rename gives its name now.
import re, sys

# the list folders (platforms.csv, column 3) and the MAME version of each
ERAS = {
    '2000': '0.37b5',   # MAME 2000
    '2003': '0.78',     # MAME 2003
    '2006': '0.106',
    '2010': '0.139',    # MAME 2010
    '2015': '0.160',    # MAME 2015
    '2016': '0.174',    # MAME 2016
    'Split': '0.260',
    'Non-Merged': '0.264',
}

def ver(v):
    m = re.match(r'(\d+)\.(\d+)(?:(b|rc|u)(\d+))?', v.strip())
    if not m:
        return None
    rank = {'b': 0, 'rc': 1, None: 2, 'u': 3}[m.group(3)]
    return (int(m.group(1)), int(m.group(2)), rank, int(m.group(4) or 0))

recs = []
for line in open(sys.argv[1], encoding='utf-8-sig'):
    p = [x.strip() for x in line.split('|')]
    if len(p) < 6 or not p[1].isdigit():
        continue
    v = ver(p[4])
    if v and p[2] and p[3]:
        recs.append((v, p[1], p[2], p[3]))
recs.sort()

by_old = {}
for v, mid, old, new in recs:
    by_old.setdefault(old, []).append((v, mid))
last = {}
for v, mid, old, new in recs:
    last[mid] = new   # sorted by version: the machine's last name wins

for folder, era in ERAS.items():
    e = ver(era)
    for old, lst in sorted(by_old.items()):
        after = [mid for v, mid in lst if v > e]
        if not after:
            continue
        now = last[after[0]]
        if now != old:
            print(f'{folder}\t{old}\t{now}')
