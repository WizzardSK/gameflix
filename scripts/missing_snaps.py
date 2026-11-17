#!/usr/bin/env python3
"""Writes MISSING_SNAPS.md: for each platform page of the site, how many of its
games have no snap in the thumbnail repo the page takes them from.

    python3 scripts/missing_snaps.py <site checkout> [MISSING_SNAPS.md] [missing.html]

The optional HTML page holds the same table, sortable by any column (click a
heading), for the site (wizzardsk.github.io/missing.html); the Markdown links
to it, as GitHub does not sort a Markdown table.

<site checkout> is a clone of WizzardSK/wizzardsk.github.io. A game's snap is
looked for as the page's script.js looks for it: Named_Snaps/<name>.png in the
repo the section names (generateFileLinks' second argument), <name> being the
entry's third field when it has one (the snap of another set or title; as
"repo/name", a snap in another repo), else
the file name without extension and without what follows its first
"(...)". The repos' file lists come from the GitHub API (gh, or GITHUB_TOKEN
with curl).
"""
import concurrent.futures as cf
import datetime
import glob
import json
import os
import re
import subprocess
import sys
import time

site = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else 'MISSING_SNAPS.md'
html_out = sys.argv[3] if len(sys.argv) > 3 else None
import html as htmlmod

SECTION = re.compile(r'fileNames\s*=\s*\[(.*?)\]\s*;?\s*\n?\s*generateFileLinks\(\s*"([^"]*)"\s*,\s*"([^"]*)"\s*\)', re.S)


def key_of(entry):
    parts = entry.split('\t')
    if len(parts) > 2 and parts[2]:
        # only a third field can name another repo ("repo/name"); a file in a
        # subfolder ("dir/file.dsk") is no repo reference
        return ('\0' + parts[2]) if '/' in parts[2] else parts[2]
    name = parts[0]
    stem = name[:name.rfind('.')] if '.' in name else name
    return re.sub(r'^([^)]*\([^)]*\)).*$', r'\1', stem)


titles = {}
pages = {}
for path in sorted(glob.glob(os.path.join(site, '*.html'))):
    page = os.path.basename(path)[:-5]
    html = open(path, encoding='utf-8', errors='replace').read()
    for m in SECTION.finditer(html):
        entries = json.loads('[' + m.group(1).strip().rstrip(',') + ']', strict=False)
        repo = re.sub(r'[^\w.-]', '-', m.group(3))
        pages.setdefault(page, {}).setdefault(repo, set()).update(key_of(e) for e in entries)

# the platform names shown on the site
for line in open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'systems.csv'), encoding='utf-8'):
    f = line.rstrip('\n').split(',')
    if len(f) >= 2 and f[0]:
        titles[f[0]] = f[1]


def tree(repo):
    url = f'repos/WizzardSK/{repo}/git/trees/master:Named_Snaps'
    # a dropped connection must not leave a platform out of the list: retry
    # everything but a real 404 (a repo or folder that doesn't exist)
    for attempt in range(5):
        if attempt:
            time.sleep(15 * attempt)
        try:
            r = subprocess.run(['gh', 'api', url], capture_output=True, text=True, timeout=300)
            if r.returncode:
                if 'HTTP 404' in r.stderr:
                    return repo, None
                continue
            d = json.loads(r.stdout)
            return repo, {t['path'][:-4] for t in d['tree'] if t['path'].endswith('.png')}
        except (OSError, subprocess.TimeoutExpired, ValueError):
            continue
    sys.exit(f'{repo}: GitHub unreachable, nothing written')


repos = sorted({r for p in pages.values() for r in p} |
               {k[1:].split('/', 1)[0] for p in pages.values() for keys in p.values()
                for k in keys if k.startswith('\0')})
with cf.ThreadPoolExecutor(8) as ex:
    have = dict(ex.map(tree, repos))

rows = []
for page, by_repo in pages.items():
    total = missing = 0
    for repo, keys in by_repo.items():
        if have.get(repo) is None:
            continue
        total += len(keys)
        # a "repo/name" key (VGMPlay) is a snap in that other repo
        missing += sum(1 for k in keys
                       if (k.startswith('\0') and k[1:].split('/', 1)[1] not in (have.get(k[1:].split('/', 1)[0]) or ()))
                       or (not k.startswith('\0') and k not in have[repo]))
    if total:
        rows.append((missing, total, page, sorted(by_repo)))
rows.sort(key=lambda r: (-r[0], r[2]))

all_total = sum(r[1] for r in rows)
all_missing = sum(r[0] for r in rows)
unreadable = [r for r in repos if have.get(r) is None]

with open(out, 'w', encoding='utf-8') as f:
    f.write('# Missing snaps\n\n')
    f.write(f'Games on the site without a snap, per platform page, as of {datetime.date.today().isoformat()}. '
            f'Regenerate with `python3 scripts/missing_snaps.py <clone of wizzardsk.github.io>`.\n\n')
    f.write(f'**{all_missing:,}** of **{all_total:,}** games have no snap ({100 * (all_total - all_missing) / all_total:.1f} % covered). '
            'The same table, sortable by any column: [wizzardsk.github.io/missing.html](https://wizzardsk.github.io/missing.html).\n\n')
    f.write('| Platform | Page | Missing | Games | Covered | Snap repos |\n|---|---|---:|---:|---:|---|\n')
    for missing, total, page, rs in rows:
        if not missing:
            continue
        f.write(f'| {titles.get(page, page)} | {page} | {missing:,} | {total:,} | {100 * (total - missing) / total:.0f} % | {", ".join(rs)} |\n')
    done = [r for r in rows if not r[0]]
    if done:
        names = sorted((titles.get(r[2], r[2]) for r in done), key=str.lower)
        names += [''] * (-len(names) % 6)
        # GitHub needs a header row: the first six names are it
        rows6 = ['| ' + ' | '.join(names[i:i + 6]) + ' |\n' for i in range(0, len(names), 6)]
        f.write(f'\n## Complete ({len(done)})\n\n' + rows6[0] + '|' + '---|' * 6 + '\n' + ''.join(rows6[1:]))
    if unreadable:
        f.write('\nNot counted (their repo could not be read): ' + ', '.join(unreadable) + '.\n')
if html_out:
    e = htmlmod.escape
    trs = ''.join(
        f'<tr><td>{e(titles.get(page, page))}</td><td><a href="{e(page)}.html">{e(page)}</a></td>'
        f'<td data-v="{missing}">{missing:,}</td><td data-v="{total}">{total:,}</td>'
        f'<td data-v="{(total - missing) / total:.4f}">{100 * (total - missing) / total:.0f} %</td><td>{e(", ".join(rs))}</td></tr>'
        for missing, total, page, rs in rows)
    open(html_out, 'w', encoding='utf-8').write(f'''<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Missing snaps</title><link rel="stylesheet" href="style.css">
<style>body{{background:#333;color:#ddd;font-family:sans-serif;margin:16px}}table{{border-collapse:collapse;width:100%}}
th,td{{padding:4px 8px;border-bottom:1px solid #555;text-align:left}}th{{cursor:pointer;position:sticky;top:0;background:#222}}
td:nth-child(3),td:nth-child(4),td:nth-child(5){{text-align:right}}a{{color:#8cf}}</style>
<h1>Missing snaps</h1>
<p>{all_missing:,} of {all_total:,} games have no snap ({100 * (all_total - all_missing) / all_total:.1f} % covered), as of {datetime.date.today().isoformat()}. Click a heading to sort.</p>
<table id="t"><thead><tr><th>Platform</th><th>Page</th><th>Missing</th><th>Games</th><th>Covered</th><th>Snap repos</th></tr></thead><tbody>{trs}</tbody></table>
<script>
document.querySelectorAll('#t th').forEach((th,i)=>th.onclick=()=>{{
  const tb=document.querySelector('#t tbody'),rows=[...tb.rows],num=i>=2&&i<=4,dir=th.dataset.d=th.dataset.d==='1'?'-1':'1';
  rows.sort((a,b)=>{{const x=a.cells[i],y=b.cells[i];return (num?(x.dataset.v-y.dataset.v):x.textContent.localeCompare(y.textContent))*dir}});
  rows.forEach(r=>tb.appendChild(r));}});
</script>
''')
print(out, all_missing, 'of', all_total)
