#!/usr/bin/env python3
# Writes mame_deps.tsv: for every MAME driver the launcher starts, the zips of
# the MAME sets it needs - its own, its parent's (a clone's ROMs are in the
# parent's zip in a merged set), its BIOS chain, and the ROM-carrying devices
# of its default configuration and of the slot cards the launcher plugs in
# ("ep128 -exp exdos"). The launcher fetches all of them; with the driver's own
# zip alone most machines stop with "Required files are missing" (a keyboard,
# a disk controller, the parent's ROMs). The third column names the machine's
# software lists, whose XML the core needs to find a software-list game by its
# short name.
#
# The input is the -listxml of the MAME version the core is built from, so the
# device names match it (mame0289lx.zip from the MAME releases on GitHub):
#   python3 gen_mame_deps.py mame0289.xml ~/gameflix/retroarch.sh > mame_deps.tsv
import re, sys, xml.etree.ElementTree as ET

xml_path, launcher = sys.argv[1], sys.argv[2]

machines = {}
for _, e in ET.iterparse(xml_path, events=('end',)):
    if e.tag != 'machine':
        continue
    slots = {}
    for s in e.findall('slot'):
        slots[s.get('name')] = {o.get('name'): o.get('devname') for o in s.findall('slotoption')}
    machines[e.get('name')] = {
        'cloneof': e.get('cloneof'),
        'romof': e.get('romof'),
        'roms': any(r.get('status') != 'nodump' for r in e.findall('rom')),
        'devices': [d.get('name') for d in e.findall('device_ref')],
        'slots': slots,
        'lists': [l.get('name') for l in e.findall('softwarelist')],
    }
    e.clear()


def deps(drv, cards):
    top = machines.get(drv)
    if top is None:
        return None
    need = []

    def add(n):
        if n and n not in need:
            need.append(n)

    add(drv)
    add(top['cloneof'])
    b = top['romof']
    while b:
        add(b)
        b = machines[b]['romof'] if b in machines else None
    seen, todo = set(), list(top['devices'])
    for slot, card in cards:
        dev = top['slots'].get(slot, {}).get(card)
        if dev:
            todo.append(dev)
    while todo:
        d = todo.pop()
        if d in seen or d not in machines:
            continue
        seen.add(d)
        if machines[d]['roms']:
            add(d)
            # a device can take its ROMs from another (i8245 from i8244)
            b = machines[d]['romof']
            while b:
                add(b)
                b = machines[b]['romof'] if b in machines else None
        todo += machines[d]['devices']
    lists = []
    for l in top['lists']:
        if l not in lists:
            lists.append(l)
    return need, lists


# Slot cards the launcher plugs in ("ep128 -exp exdos -flop", "mo5 -extension
# cd90_640 -flop") bring ROM devices of their own; they are added to the
# driver's line, so every list of that driver fetches them.
cards = {}
for core in re.findall(r'core="mame(?:_libretro)? ([^"]*)"', open(launcher).read()):
    w = core.split()
    d = w[0]
    cards.setdefault(d, set())
    slots = machines.get(d, {}).get('slots', {})
    for i in range(1, len(w) - 1):
        if w[i].startswith('-') and w[i][1:] in slots and not w[i + 1].startswith('-'):
            cards[d].add((w[i][1:], w[i + 1]))
for d in sorted(cards):
    r = deps(d, sorted(cards[d]))
    if r:
        print(d + '\t' + ' '.join(r[0]) + '\t' + ' '.join(r[1]), flush=True)
