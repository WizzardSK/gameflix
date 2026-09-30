#!/usr/bin/env python3
# Writes mame_deps.tsv: for every MAME driver the launcher starts, the zips of
# the merged MAME set it needs - the zip holding the machine (the parent's, for
# a clone), its BIOS chain, and the ROM-carrying devices of its default
# configuration (-listdevices, not every slot option). The launcher fetches all
# of them; with the driver's own zip alone most machines stop with "Required
# files are missing" (a keyboard, a disk controller, the parent's ROMs). The
# third column names the machine's software lists, whose XML the core needs to
# find a software-list game by its short name.
#
# Needs a standalone MAME for -listxml/-listdevices (apt install mame):
#   python3 gen_mame_deps.py ~/gameflix/retroarch.sh > mame_deps.tsv
import re,shutil,subprocess,sys,xml.etree.ElementTree as ET
MAME=shutil.which('mame') or '/usr/games/mame'
def deps(drv):
    x=subprocess.run([MAME,'-listxml',drv],capture_output=True,text=True).stdout
    if not x.strip(): return None
    m={e.get('name'):e for e in ET.fromstring(x).findall('machine')}
    top=m.get(drv)
    if top is None: return None
    need=[]
    def add(n):
        if n and n not in need: need.append(n)
    add(top.get('cloneof') or drv)
    b=top.get('romof')
    while b:
        add(b); b=m[b].get('romof') if b in m else None
    tree=subprocess.run([MAME,'-listdevices',drv],capture_output=True,text=True).stdout
    used=set()
    for l in tree.split('\n')[1:]:
        mm=re.match(r'\s*\S+\s{2,}(.*?)(?: @ [\d.]+ [kMG]?Hz)?$',l)
        if mm: used.add(mm.group(1))
    for n,e in m.items():
        if e.get('isdevice')=='yes' and e.find('rom') is not None and e.findtext('description') in used:
            add(n)
    lists=[]
    for l in top.findall('softwarelist'):
        if l.get('name') not in lists: lists.append(l.get('name'))
    return need,lists
drivers=sorted(set(re.findall(r'core="mame(?:_libretro)? ([a-z0-9_]+)',open(sys.argv[1]).read())))
for d in drivers:
    r=deps(d)
    if r: print(d+'\t'+' '.join(r[0])+'\t'+' '.join(r[1]),flush=True)
