# Typst cookbook for study-notes-builder

Target: **Typst 0.15.x**. Read this before writing any `.typ`. The syntax-trap
list at the bottom is the important part — each item there is a real failed
compile from building these notes.

## Environment check

```sh
typst --version                 # want 0.15.x; cetz 0.5.x + physica need >= 0.14
typst fonts | grep -i "computer modern"   # need "New Computer Modern" + "...Math"
curl -sI https://packages.typst.org/preview/index.json | head -1   # 200 = registry reachable
```

First compile downloads ~12 `@preview` packages into `~/.cache/typst`. After
that it is fully offline. If the registry is unreachable, vendor the packages
into `<proj>/packages/` and import with a local spec.

## Imports and required setup (versions: run `scripts/sync-versions.sh`)

```typ
#import "@preview/great-theorems:0.1.2": *
#import "@preview/rich-counters:0.2.2": *
#import "@preview/codly:2.0.0" as codly
#import "@preview/codly-languages:0.1.10": codly-languages
#import "@preview/showybox:2.0.4": showybox
#import "@preview/hydra:0.6.3": hydra
#import "@preview/physica:0.9.8" as phys
#import "@preview/tablem:0.3.0": tablem
#import "@preview/cetz:0.5.3"
#import "@preview/cetz-plot:0.1.4": plot
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
```

Mandatory show-rules, once, inside the document config function, in this order:

```typ
// codly 2.x (the 1.x `codly-init` / `codly(...)` API is gone):
show: codly.lang-set_(languages: codly-languages)
show: codly.set_(padding: 0.55em, radius: 4pt, gutters: ())   // gutters: () = no line numbers
show: codly.line-set_(fill: c-bg-soft)
show raw.where(block: true): codly.new
show: great-theorems-init        // REQUIRED for mathblock numbering/alignment
```

`great-theorems` blocks:

```typ
#let _mathcnt = rich-counter(identifier: "mb", inherited_levels: 1)   // NOTE underscore
#let definition = mathblock(blocktitle: "Definition", counter: _mathcnt,
  titlix: title => [ (#title).])                                      // no custom `prefix`
```

`hydra` in the page header must run in `context`:

```typ
header: context { set text(size: 8.5pt); hydra(1); h(1fr); [Notes] }
```

## Syntax traps (each cost a failed compile)

1. **Mid-word `*emphasis*` fails** with `unclosed delimiter`.
   `*Ada*ptive` → the closing `*` is not at a word boundary → parser never
   closes it. Use `#strong[Ada]ptive` (or bold the whole word).

2. **Mismatched brackets inside `$…$` = `unclosed delimiter`.**
   `$[0, infinity)$`, `$alpha in (0, 1]$`, `$(0, 1]$` all fail — Typst math
   pairs `[`/`]` and `(`/`)`. Fixes: write the interval as prose (`` `[0, ∞)` ``)
   or as an inequality (`$0 < alpha <= 1$`), or wrap in `lr("(" ... "]")`.

3. **`tablem` rejects an empty header cell.** `| | A | B |` →
   `equality assertion failed: There should be a linebreak…`.
   Use `| #" " | A | B |`.

4. **`#` inside a `tablem` cell** starts a Typst expression →
   `expected expression`. Escape as `\#` or reword ("number of").

5. **`emoji.*` names are limited.** `emoji.bulb` fails; `emoji.lightbulb`,
   `emoji.pencil`, `emoji.warning` work. `emoji.memo` fails. Probe before use:
   `#emoji.lightbulb` in a scratch file.

6. **`rich-counter(inherited_levels: 1)`** — underscore, not `inherited-levels`
   (0.2.2). The hyphen form errors `unexpected argument`.

7. **`great-theorems` `mathblock` with a `counter` needs an auto prefix.**
   Passing `prefix: [*Definition*]` (content, not a function) panics
   "inconsistent". Omit `prefix`; customise via `titlix` only.

8. **Numbering patterns need a counting symbol.** `numbering: "Step 0."` →
   `invalid numbering pattern` (`0` is literal). Use `numbering: "Step 1.",
   start: 0`. `"P1."` is fine (`1` is the symbol).

9. **`show par: set block(spacing: …)`** → warning "no effect anymore". Use
   `set par(spacing: …)`.

10. **`{:}` / `{+}` / `{-}` / `{=}` in math render literal braces.**
    `$(1,1){:}1$` shows `{:}`. Typst math braces are literal characters. For a
    pair separator use `$(1,1) -> 1$`. For tight operators just write `+` / `-`.

11. **`a/b` in prose math becomes a fraction.** `$-1/+1$` renders as a fraction.
    Use separate spans `$-1$/$+1$` or `plus.minus 1`.

12. **`fletcher` edges need node names as *labels*, not strings.**
    `edge("a", "b", "->")` → "Couldn't interpret edge() arguments". Give nodes
    `name: label("a")` and reference `edge(label("a"), label("b"), "->")`. Helper
    in `diagrams.typ`: `#let nm(s) = label(s)`.

13. **`fletcher` bundles its own internal CeTZ (0.3.4)** separate from the
    `cetz:0.5.3` you import for plots. Both coexist; don't mix their draw APIs.

14. **`cetz-plot` must pair with a compatible `cetz`** (>= 0.5.0). Use
    `cetz:0.5.3` + `cetz-plot:0.1.4`. `plot.plot(size: (w,h), …)` goes *inside*
    `cetz.canvas`; series via `plot.add(domain: (a,b), x => …)`.

15. **`showybox` accepts `spacing` / `above` / `below`** for outer gaps and
    `frame: (inset: …)` for inner padding — use these to tune page density.

16. **Standalone-compiling a `sections/*.typ`** that imports `"../template.typ"`
    fails with "would escape the project root". Add `--root .` or just compile
    `main.typ`.

## Page-density tuning (the "weird gaps" fix)

The template ships **without** a `pagebreak` on the level-1 heading show rule —
that alone causes half-empty pages. If you re-add one, expect gaps.

Levers, in order of impact:
- `set par(leading: 0.62em, spacing: 0.95em)` — tighten for density.
- `worked` / `algo` / `practice` showyboxes: `frame: (… inset: 0.75em)` and
  `spacing: 0.85em, above: 0.85em, below: 0.85em`.
- level-1 heading `block(above: 1.8em, below: 0.9em, breakable: false)` —
  enough to separate chapters visually without a page break.
- `page(margin: (x: 2.3cm, y: 2.4cm))` — keep margins symmetric. Mirrored
  `inside`/`outside` margins make alternate pages drift left/right; never use them.

Some tail gap from an unbreakable callout that jumped whole is normal and fine.

## Compile / review commands

```sh
typst compile main.typ out.pdf                 # build
typst watch main.typ                           # iterate
typst compile main.typ out.pdf 2>&1 | grep -iE "error|warning"   # gate: must be empty
typst compile --pages 20-25 main.typ "/tmp/rev/p-{p}.png" --ppi 90   # visual review
pdfinfo out.pdf | grep Pages
```

## Package catalog (Typst Universe) — search before you draw

The baseline stack in SKILL.md is only a starting point. Before drawing anything
domain-specific, look for a package. Registry index (JSON, ~2k packages):

```sh
curl -sL https://packages.typst.org/preview/index.json -o /tmp/idx.json
python3 -I -c "import json,re;d=json.load(open('/tmp/idx.json'));\
l={};[l.__setitem__(p['name'],p) for p in d];\
[print(n,p['version'],p.get('description','')[:80]) for n,p in sorted(l.items()) if re.search(r'KEYWORD',n+p.get('description',''),re.I)]"
```

Use the latest version (`scripts/sync-versions.sh` does it); check the package page
(`https://typst.app/universe/package/<name>`) for the API before use. Probe in a
scratch file first. Snapshot of what existed (verify versions, they move):

| Domain | Packages |
|---|---|
| Quantum | `quill` (circuits), `czbloch` / `tybloch` (Bloch sphere), `atostate`, `qec-thrust` |
| General diagrams | `fletcher` (nodes/arrows), `cetz`, `diagraph` (Graphviz), `chronos` + `pintorita` (sequence/ER/activity/component), `autofletcher` |
| Software eng / SDLC | `mastermind`, `sourcecraft` (UML class), `gantty`, `timeliney` (Gantt), `chronos` (sequence), `pintorita` |
| Systems / parallel / MPI | `blockcell`, `bytefield` (memory maps, headers), `cntopo` (network topology), `fletcher` for rank/message graphs |
| Digital logic / HW | `circuiteria` (block circuits), `zap` (electronic circuits), `digidraw` / `wavy` (timing), `k-mapper` / `karnaugh-express` / `convenient-karnaughs`, `truthfy` |
| Automata / logic / proofs | `finite` (DFA/NFA), `flautomat`, `curryst` / `prooflists` (inference trees), `fitchcraft`, `boxproof`, `derive-it` |
| Trees / graphs | `tdtr`, `arborly`, `twig`, `syntree`, `treet`, `probabilitree`, `genealotree` |
| ML / AI | `neural-netz`, `neural-viz`, `confy` (confusion matrix), `lilaq` |
| Plots / data | `lilaq` (scientific plots, richer than cetz-plot), `cetz-plot`, `cetz-venn`, `riesketcher` |
| Physics | `physica`, `patatrac`, `inknertia`, `cetz-feynman-lite`, `typed-physics`, `solving-physics` |
| Chemistry | `alchemist`, `typsium`, `chemformula`, `molchemist`, `michem` |
| Control | `consketcher` (control block diagrams) |
| Algorithms / code | `algorithmic`, `lovelace`, `algorythmst`, `codly` (now 2.0.x), `zebraw` |
| Math prose | `equate`, `mannot` (annotate equations), `mitex`, `quick-maths`, `ctheorems`, `theorion`, `thmbox` |
| Layout / annotation | `marginalia` / `drafting` (margin notes), `wrap-it` (text wrap), `subpar` (sub-figures), `pinit`, `tiptoe` (arrow tips), `chalks` / `scrawl` (hand-drawn look), `glossarium`, `booktabs` |

Import-to-fit rule: if a package fails to compile on this Typst version, drop it
and fall back to `cetz`/`fletcher`; do not burn more than 2 compile attempts.

## Screenshots from source material

```sh
pdftoppm -r 200 -f P -l P -png src.pdf /tmp/fig/p           # whole page
pdftoppm -r 200 -f P -l P -x X -y Y -W W -H H -png src.pdf /tmp/fig/crop   # crop region
pdfimages -png -f P -l P src.pdf /tmp/fig/img               # embedded raster figures
```

Look at the PNG (Read) to pick the crop box, then embed:
`#figure(image("figs/p12-mlp.png", width: 75%), caption: [... #sref[Lecture 3, slide 12]])`.
Crop tight (no slide chrome or page numbers), 200 dpi, one idea per image.

17. **Major package bumps break calls.** After `sync-versions.sh`, an
    `unresolved import` / `unknown named field` error means the API changed
    (codly 1.x -> 2.x did). Read the README in `~/.cache/typst/packages/` instead
    of guessing.
18. **`import "@preview/x": *` can shadow built-ins** (`ref`, `link`, ...) and
    give "only element functions can be used as selectors". Import by name or
    `as alias`.

## Verified gotchas from the gallery (full demos in `gallery/`)

- `twig` breaks on cetz 0.5.3; alias an older cetz for it. `gantty`: poor output, use `timeliney`.
- `sourcecraft` default font "Consolas" and `marginalia` marker font "Inter" warn when missing; pass your own font. A partial `sourcecraft` theme crashes; pass a full dict.
- `lovelace` 0.3.1 has no `comment()`; use `#h(1fr)`. Use `title:` not `numbered-title:` outside figures.
- `pinit` pins and highlights must share a page: wrap in `block(breakable: false)`.
- `marginalia` narrows the text column by its gutter: asymmetric by design; set `book: false`. Prefer it over `drafting` (which boxes notes).
- `fletcher` turns small nodes into circles: use `node.with(shape: rect)`.
- `bytefield`: one `bitheader` per diagram. `cntopo`: use its re-exported `cetz`.
- `k-mapper` `manual-terms` must list all 2^n cells in minterm order.
- `lilaq`: `mark: none` and `legend: (position: left + top)` to keep legends off curves. `cetz-plot`: set tick steps.
- `neural-netz` is CNN-only; draw MLPs with fletcher. `diagraph` labels are Typst math: write `h_1`, no `$`.
