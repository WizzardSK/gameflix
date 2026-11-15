#!/usr/bin/env python3
"""Writes vgmplay_snaps.tsv: a snap for VGMPlay soundtracks that have none in
the MAME repo under their own name.

    python3 scripts/vgmplay_snaps.py <site checkout> [vgmplay_snaps.tsv]

MAME's vgmplay software list has the soundtracks of console, computer and
arcade games, named <game>_<system> for the non-arcade ones (sonic_md,
10yard_nes). A soundtrack takes the snap of its game:

- a console or computer one from that system's snap repo, by the title in
  its description ("Sonic the Hedgehog (GEN/MD)" -> "Sonic The Hedgehog (USA,
  Europe)"), preferring a USA, then World, Europe and Japan release;
- an arcade one from the MAME repo, the set whose title matches (the page's
  arcade list, mame.html).

Each line is "<software name>\\t<repo>/<snap name>", or "<software name>\\t<set>"
for the MAME repo; generate.sh writes it as the entry's third field, which the page
(platform.js) reads as a snap in another repo when it holds a "/". The repos'
file lists come from the GitHub API (gh).
"""
import json
import re
import subprocess
import sys
import urllib.request

site = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else 'vgmplay_snaps.tsv'

# system suffix -> snap repo
REPO = {}
for repo, sfx in {
    'Sega_-_Mega_Drive_-_Genesis': 'md',
    'Sega_-_Mega-CD_-_Sega_CD': 'mcd scd',
    'Sega_-_32X': '32x',
    'Sega_-_Master_System_-_Mark_III': 'sms smsfm',
    'Sega_-_Game_Gear': 'gg',
    'Nintendo_-_Nintendo_Entertainment_System': 'nes fc nest den',
    'Nintendo_-_Family_Computer_Disk_System': 'fds',
    'Nintendo_-_Game_Boy': 'gb sgb',
    'Nintendo_-_Game_Boy_Color': 'gbc',
    'Nintendo_-_Virtual_Boy': 'vb vboy',
    'NEC_-_PC_Engine_-_TurboGrafx_16': 'tg16 pce',
    'NEC_-_PC_Engine_CD_-_TurboGrafx-CD': 'pcecd tgcd',
    'NEC_-_PC_Engine_SuperGrafx': 'sgx',
    'NEC_-_PC-98': '98 98o 98oa 98o3 98on pc98',
    'NEC_-_PC-8001_-_PC-8801': '88 88o 88oa 88on 88va pc88',
    'Sharp_-_X68000': '68k x68',
    'Microsoft_-_MSX': 'msx msxfm',
    'Microsoft_-_MSX2': 'msx2 msx2o msx2p msx2m msx2f msx2a msxf msxm psg scc ssc',
    'MSX_-_TurboR': 'msxr',
    'Atari_-_ST': 'st',
    'Sinclair_-_ZX_Spectrum': 'zxs zx',
    'Fujitsu_-_FM_Towns': 'fmt',
    'SNK_-_Neo_Geo_Pocket_Color': 'ngpc',
    'Bandai_-_WonderSwan_Color': 'wsc',
    'DOS': 'pc at pco pcj t1k dos',
}.items():
    for s in sfx.split():
        REPO[s] = repo
ARCADE = {'', 'bsys', 's18', 'sysc', 'w95', 'igs', '2610', '2203'}


def key(title):
    """The title before its brackets, small letters and figures only, II to
    IV as figures, & as and (generate.sh's game_key)."""
    s = re.split(r' \(| \[', title)[0]
    s = ' ' + s.lower() + ' '
    for a, b in ((' iii ', ' 3 '), (' ii ', ' 2 '), (' iv ', ' 4 '), ('&', 'and')):
        s = s.replace(a, b)
    return re.sub(r'[^a-z0-9]', '', s)


def tree(repo):
    r = subprocess.run(['gh', 'api', f'repos/WizzardSK/{repo}/git/trees/master:Named_Snaps'],
                       capture_output=True, text=True)
    if r.returncode:
        return []
    return [t['path'][:-4] for t in json.loads(r.stdout)['tree'] if t['path'].endswith('.png')]


def rank(name):
    for i, r in enumerate(('(USA', '(World', '(Europe', '(Japan')):
        if r in name:
            return i
    return 9


def page_entries(page):
    html = open(f'{site}/{page}.html', encoding='utf-8', errors='replace').read()
    out = []
    for m in re.finditer(r'fileNames\s*=\s*\[(.*?)\]\s*;?\s*\n?\s*generateFileLinks', html, re.S):
        out += json.loads('[' + m.group(1).strip().rstrip(',') + ']', strict=False)
    return out


mame_snaps = set(tree('MAME'))
vgm = [e.split('\t') for e in page_entries('vgmplay')]
# arcade titles with a snap, from the arcade page: title key -> set
mame_by_key = {}
for e in page_entries('mame'):
    f = e.split('\t')
    if len(f) < 2:
        continue
    sn = f[0].rsplit('.', 1)[0]
    if sn in mame_snaps:
        for part in f[1].split(' / '):
            mame_by_key.setdefault(key(part), sn)

indexes = {}
lines = []
for f in vgm:
    name = f[0].rsplit('.', 1)[0]
    desc = f[1] if len(f) > 1 else name
    if name in mame_snaps:
        continue
    sfx = name.rsplit('_', 1)[1] if '_' in name else ''
    titles = [desc, desc.split(' - ', 1)[1]] if ' - ' in desc else [desc]
    if sfx in ARCADE or (sfx not in REPO and '(' in desc and 'Arcade' in desc):
        for t in titles:
            sn = mame_by_key.get(key(t))
            if sn:
                lines.append(f'{name}\t{sn}')
                break
        continue
    repo = REPO.get(sfx)
    if not repo:
        continue
    if repo not in indexes:
        idx = {}
        for sn in tree(repo):
            idx.setdefault(key(sn), []).append(sn)
        indexes[repo] = idx
    for t in titles:
        cand = indexes[repo].get(key(t))
        if cand:
            lines.append(f'{name}\t{repo}/{min(cand, key=lambda n: (rank(n), n))}')
            break

with open(out, 'w', encoding='utf-8') as fh:
    fh.write('\n'.join(sorted(lines)) + '\n')
print(out, len(lines), 'of', sum(1 for f in vgm if f[0].rsplit('.', 1)[0] not in mame_snaps), 'without a MAME snap')
