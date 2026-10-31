#!/usr/bin/env python3
"""Structure lint for sections/*.typ: fails prose-heavy notes.
Usage: structure-check.py <proj>
Per file: words per heading, share of long paragraphs, boxes, bullets/tables, figures per words."""
import re, sys
from pathlib import Path

MAX_WORDS_PER_HEADING = 150
MAX_PARA_WORDS = 60
MAX_LONG_PARA_SHARE = 0.10
MIN_BOXES_PER_1000W = 2.5     # definition/theorem/property/keyform/worked
MIN_LIST_ITEMS_PER_1000W = 8  # bullets, numbered steps, table rows
MIN_FIGS_PER_1000W = 1.0      # #figure / diagram calls

BOX = re.compile(r"#(definition|theorem|property|keyform|worked|pitfall|intuition)\b")
FIG = re.compile(r"#(figure|diagram|fletcher|cetz\.canvas|canvas)\b|#image\(")
bad = 0
for f in sorted((Path(sys.argv[1]) / "sections").glob("*.typ")):
    lines = f.read_text().splitlines()
    heads = sum(1 for l in lines if re.match(r"^=+ ", l))
    boxes = sum(len(BOX.findall(l)) for l in lines)
    figs = sum(len(FIG.findall(l)) for l in lines)
    items = sum(1 for l in lines if re.match(r"^\s*([-+]|\d+\.) ", l) or l.lstrip().startswith("|") or "#tablem" in l or "#table(" in l)
    paras, cur = [], []
    for l in lines + [""]:
        t = l.strip()
        plain = t and not re.match(r"^(#|=|-|\+|\d+\.|\||\$|//|\]|\)|\[|\})", t)
        if plain:
            cur.append(t)
        elif cur:
            paras.append(len(" ".join(cur).split()))
            cur = []
    words = sum(len(l.split()) for l in lines if l.strip() and not l.strip().startswith(("//", "#import", "#let")))
    kw = max(words / 1000, 0.001)
    wph = words / max(heads, 1)
    long_share = sum(1 for p in paras if p > MAX_PARA_WORDS) / max(len(paras), 1)
    probs = []
    if wph > MAX_WORDS_PER_HEADING: probs.append(f"{wph:.0f} words/heading (max {MAX_WORDS_PER_HEADING}): add subheadings")
    if long_share > MAX_LONG_PARA_SHARE: probs.append(f"{long_share:.0%} paragraphs > {MAX_PARA_WORDS} words: convert to bullets/tables")
    if boxes / kw < MIN_BOXES_PER_1000W: probs.append(f"{boxes/kw:.1f} boxes/1000w (min {MIN_BOXES_PER_1000W}): add definitions/formula/examples")
    if items / kw < MIN_LIST_ITEMS_PER_1000W: probs.append(f"{items/kw:.1f} list/table items/1000w (min {MIN_LIST_ITEMS_PER_1000W})")
    if figs / kw < MIN_FIGS_PER_1000W: probs.append(f"{figs/kw:.1f} figures/1000w (min {MIN_FIGS_PER_1000W}): add diagrams/screenshots")
    print(f"{f.name}: {words}w, {heads} headings, {boxes} boxes, {items} list items, {figs} figures -> {'OK' if not probs else 'FAIL'}")
    for p in probs: print("  -", p)
    bad += bool(probs)
print("OK" if not bad else f"FAIL ({bad} files too prose-heavy; fix then rerun)")
sys.exit(1 if bad else 0)
