#!/usr/bin/env bash
# Rewrite every @preview/<pkg>:<ver> import in the given .typ files/dirs to the latest registry version.
# Usage: sync-versions.sh <file-or-dir>...   (prints each change; needs network)
set -euo pipefail
idx=$(mktemp); trap 'rm -f "$idx"' EXIT
curl -fsSL https://packages.typst.org/preview/index.json -o "$idx"
python3 -I - "$idx" "$@" <<'P'
import json, re, sys, pathlib
v = lambda s: tuple(int(x) for x in s.split('.'))
latest = {}
for p in json.load(open(sys.argv[1])):
    if p['name'] not in latest or v(p['version']) > v(latest[p['name']]): latest[p['name']] = p['version']
files = []
for a in sys.argv[2:]:
    q = pathlib.Path(a); files += sorted(q.rglob('*.typ')) if q.is_dir() else [q]
pat = re.compile(r'@preview/([a-z0-9-]+):(\d+\.\d+\.\d+)')
for f in files:
    s = f.read_text()
    def sub(m):
        n, old = m.groups(); new = latest.get(n)
        if not new: print(f'{f}: {n} not in registry'); return m.group(0)
        if new != old: print(f'{f}: {n} {old} -> {new}')
        return f'@preview/{n}:{new}'
    t = pat.sub(sub, s)
    if t != s: f.write_text(t)
P
