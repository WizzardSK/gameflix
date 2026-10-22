#!/usr/bin/env python3
"""Lists the PICO-8 or Voxatron carts of the Lexaloffle BBS for generate.sh.

Usage: lexaloffle.py pico8|voxatron > fantasy/<name>.txt

Each listing page holds its entries in a pdat array - post, thread ID, title,
thumbnail - and a cart's file is named after its thumbnail, so the cart pages
themselves are not fetched:
  thumbs/pico8_<name>.png -> <name>.p8.png    thumbs/pico<n>.png -> <n>.p8.png
  thumbs/vox_<name>.png   -> <name>.vx.png    thumbs/vox<n>.png  -> cpost<n>.png
An entry with another kind of thumbnail (a PICO-8 cart posted among the
Voxatron ones) is left out. Output, per category: a "---<TAB>category" line,
then "<thread ID><TAB><title><TAB><cart file>" lines, newest thread first.
"""
import concurrent.futures
import re
import sys
import time
import urllib.request

CONSOLES = {
    "pico8": (7, [(2, "Releases"), (3, "WIP"), (8, "Jam"), (9, "Code"), (14, "GFX"), (15, "SFX / Music")],
              [(r"/pico8_(.+)\.png$", "{}.p8.png"), (r"/pico(\d+)\.png$", "{}.p8.png")]),
    "voxatron": (6, [(2, "Releases"), (3, "WIP")],
                 [(r"/vox_(.+)\.png$", "{}.vx.png"), (r"/vox(\d+)\.png$", "cpost{}.png")]),
}
ENTRY = re.compile(r"\[\s*'\d+',\s*(\d+),\s*`([^`]*)`,\s*\"([^\"]*)\"")


def fetch(url):
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "gameflix"})
            return urllib.request.urlopen(req, timeout=60).read().decode("utf-8", "replace")
        except OSError as e:
            print(f"{url}: {e}, retrying", file=sys.stderr)
            time.sleep(5 * (attempt + 1))
    sys.exit(f"{url}: giving up")


def cart_file(thumb, rules):
    for pattern, name in rules:
        m = re.search(pattern, thumb)
        if m:
            return name.format(m.group(1))
    return None


def main():
    cat, subs, rules = CONSOLES[sys.argv[1]]
    for sub, catname in subs:
        # Pages are fetched ten at a time, up to the first one without entries
        carts, page, done = {}, 1, False
        url = f"https://www.lexaloffle.com/bbs/lister.php?cat={cat}&sub={sub}&mode=carts&page={{}}"
        with concurrent.futures.ThreadPoolExecutor(10) as pool:
            while not done:
                for html in pool.map(fetch, [url.format(page + i) for i in range(10)]):
                    entries = ENTRY.findall(html)
                    if not entries:
                        done = True
                        break
                    for tid, title, thumb in entries:
                        cart = cart_file(thumb, rules)
                        if cart:
                            carts[int(tid)] = (title.replace("\t", " "), cart)
                    page += 1
        print(f"{catname}: {page - 1} pages, {len(carts)} carts", file=sys.stderr)
        print(f"---\t{catname}")
        for tid in sorted(carts, reverse=True):
            print(f"{tid}\t{carts[tid][0]}\t{carts[tid][1]}")


main()
