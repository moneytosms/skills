#!/usr/bin/env python3
"""Check coverage.md: every source page mapped or skipped. Prints the notes/source page ratio for information only.

coverage.md rows (markdown table): | source.pdf | page | topics | section file or "skip: reason" |
Usage: coverage-check.py <proj> [--src DIR]
"""
import argparse, re, subprocess, sys
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument("proj")
ap.add_argument("--src", help="source dir (default: parent of proj)")
a = ap.parse_args()
proj = Path(a.proj).resolve()
src = Path(a.src).resolve() if a.src else proj.parent

def pages(pdf):
    out = subprocess.run(["pdfinfo", str(pdf)], capture_output=True, text=True).stdout
    return int(re.search(r"^Pages:\s+(\d+)", out, re.M).group(1))

def expand(spec):
    for part in re.split(r"[,\s]+", spec.strip()):
        m = re.fullmatch(r"(\d+)(?:-(\d+))?", part)
        if m:
            yield from range(int(m[1]), int(m[2] or m[1]) + 1)

cov = {}
for line in (proj / "coverage.md").read_text().splitlines():
    c = [x.strip() for x in line.strip().strip("|").split("|")]
    if len(c) >= 4 and c[0].endswith(".pdf"):
        for p in expand(c[1]):
            cov.setdefault(c[0], {})[p] = c[3]

bad = 0
total_src = 0
for pdf in sorted(src.glob("*.pdf")):
    if pdf.resolve() == (proj / "out.pdf").resolve():
        continue
    n = pages(pdf)
    total_src += n
    got = cov.get(pdf.name, {})
    missing = [p for p in range(1, n + 1) if p not in got]
    unfilled = [p for p, v in got.items() if not v or v.lower() in ("todo", "tbd")]
    skips = sum(1 for v in got.values() if v.lower().startswith("skip"))
    print(f"{pdf.name}: {n} pages, {len(got)} mapped, {skips} skipped, {len(missing)} unmapped")
    if missing:
        print(f"  unmapped: {missing[:30]}{' ...' if len(missing) > 30 else ''}")
    bad += len(missing) + len(unfilled)

out = proj / "out.pdf"
note_pages = pages(out) if out.exists() else 0
print(f"notes: {note_pages} pages for {total_src} source pages (info only, no length target)")
print("OK" if not bad else f"FAIL ({bad} problems)")
sys.exit(1 if bad else 0)
