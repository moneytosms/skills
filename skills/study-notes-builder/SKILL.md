---
name: study-notes-builder
description: Build a single polished PDF of detailed, exam-oriented study notes from source material — lecture PDFs/PPTs, existing notes, a syllabus, or just a list of topics. Use when the user asks to "make notes / a cheatsheet / detailed notes / a study guide" for a subject and wants intuition + formulae + worked examples + diagrams + pitfalls, built with Typst. Searches Typst packages for domain diagrams, uses a verified diagram gallery and latest package versions. Runs an intake → grill → digest/recon → verify-numerics → build → review loop and delivers a compiled PDF plus modular .typ sources.
---

# Study Notes Builder

Turn whatever the user hands you (PDFs, PPTX, images, a syllabus, a topic list)
into one cohesive PDF of **detailed, simple-to-read, visual study notes**: every
topic runs *intuition → mathematics → boxed algorithm → verified worked examples
→ common pitfalls → practice*, in syllabus order, with a consistent visual
language and exam-focused end-matter.

Built with **Typst** and a fixed, proven package stack. Source extraction uses
**`lit`** (liteparse) when it is installed, else the Read tool.

## When this applies

Trigger phrases: "make notes / cheatsheet / detailed notes / revision notes /
study guide for <subject>", "turn these PPTs into notes", "notes from this
syllabus", "cover these topics as notes". The user usually attaches PDFs/PPTs or
names topics.

Not this skill: writing a single short explainer, editing an existing prose
doc, or answering one conceptual question.

## Hard rules

1. **Grill before building.** Never start writing sections until the user has
   answered the intake questions and approved a plan. Use the round-based
   question format in step 3.
2. **Verify every number.** Every worked numerical example is recomputed from
   scratch in a throwaway script (`scratchpad/verify/*.py`) and the notes show
   the verified value. Where it diverges from the source deck, add a margin note.
   Do this *before* writing the prose for that section.
3. **Zero-warning compile gate.** `typst compile main.typ out.pdf` must exit 0
   with no warnings (Typst warns on overflow boxes and unresolved refs — treat
   any as a defect).
4. **Augment, don't transcribe.** Fill gaps the source assumes (foundational
   definitions, adjacent topics it leads into) from your knowledge base — but
   stay inside the scope the user set in the grill.
5. **Read `references/typst-cookbook.md` before writing any `.typ`.** It carries
   the version notes, import/setup lines, the package catalog and the Typst
   syntax traps that will otherwise cost you several failed compiles.
6. **Search for packages before drawing.** Run the package scout (step 2); do
   not default to the baseline stack when a domain package exists.
7. **Every internal self-reference is a live hyperlink, both ways.** Whenever the
   notes point at another part of themselves — "see Appendix C", "the recall
   formula above", "as in the perceptron worked example", "Part II covers this" —
   that phrase must be a clickable link to the target, and the target must carry
   a subtle backlink to the referring spot. Use `xref` / `backlink` from
   `template.typ`: label the target heading/block `<app-c>`, write the mention as
   `#xref(<app-c>)[Appendix C]` and give the call site its own label
   `<q-bpn-appc>`, then place `#backlink(<q-bpn-appc>)` at the target. A target
   referenced from N spots gets N stacked `#backlink(...)` markers. This applies
   to the practice-answer-key ↔ practice-question link, the pitfall-index ↔
   body-callout link, and formula-sheet ↔ first-derivation link especially.

## Workflow

### 1. Intake — gather and extract sources

- List what the user gave: file paths, topic list, syllabus text.
- If `lit` is installed (`command -v lit`), batch-extract every document to
  text: `bash <skill>/scripts/extract.sh "<src_dir>" "<out_dir>"`
  (wraps `lit parse`; falls back to per-file). Otherwise Read each file
  (PDFs via the `pages` arg).
- **Image-heavy sources:** slides that are pictures or scans have little or no
  text layer. `extract.sh` flags pages with under 15 words
  (`<name>.imgpages.txt`) and OCRs them with `tesseract` (`<name>.ocr.txt`). For
  PPTX/images and for flagged pages, also render the page (`pdftoppm -r 150`)
  and Read the PNG: OCR misses diagrams, tables and formulas. Digest agents must
  report OCR quality per source and treat flagged pages as content to cover,
  not skip. Tell the user which sources were OCR'd.
- If the user gave only topics / a syllabus with no documents, note that the
  build is knowledge-base-driven and the digest step is skipped.

### 2. Digest — understand the material (subagent)

Dispatch one `Explore` (or `general-purpose`) subagent over the extracted text.
Ask it to report, per source:

- topic/title, ordered concept list
- every formula (transcribed from the OCR as best it can)
- every worked numerical example (inputs given, method)
- diagrams/architectures described
- OCR quality (clean / messy / garbled), and which pages needed OCR or a visual read

…then a synthesis: the logical teaching order across all sources, the topic
clusters, and **which standard syllabus topics are absent** (so you can propose
augmentation). Keep the subagent read-only.

Alongside it, launch these read-only subagents in the same message, each
returning a short report with an explicit "nothing found" where applicable:

- **Package scout**: given the subject and the list of diagram-worthy concepts
  (e.g. Bloch sphere, MPI message flow, SDLC/Gantt, DFA, UML, circuits), search
  the Typst Universe index (cookbook "Package catalog") and `typst.app/universe`
  for packages that draw them. Return: package, latest version, one-line API
  sketch, and a minimal snippet it has compiled in a scratch file. Also report
  anything better than the baseline for tables, math annotation, plots
  (`lilaq`), margin notes.
- **Figure scout** (if sources are PDFs/slides): render candidate figure pages
  to PNG and report the crop box for each usable figure.

### 3. Grill — resolve the design tree

Work in **rounds**. Each round asks every question whose prerequisites are
settled; number them and give a recommended answer; then wait. Format:

```
❓ **Q1 — <title>**: <body, with options>

➡️ <your recommended answer>
```

Cover at least:

- **Scope / augmentation depth** — source topics only + light augmentation, or
  source topics + the adjacent foundations they assume, or the full standard
  syllabus. (Recommend the middle.)
- **Purpose & notation** — which exam/board/textbook to align notation to (infer
  from the decks if possible, e.g. a named textbook); cheatsheet vs teaching
  notes.
- **Worked-example treatment** — recompute all source problems + N extra solved
  per topic + M practice questions with an answer-key appendix. (Recommend
  recompute-all, 2 extra, 3–5 practice.)
- **Visual investment** — how far to go on diagrams, and which concepts get
  custom diagrams (propose packages from the scout), e.g. architecture
  node-graphs, function plots, geometry sketches, signal-flow.
- **Document skeleton** — the ordered part/chapter list; confirm it.
- **Deliverable form** — `.typ` sources + compiled PDF + README (default yes).
- **Source screenshots** — include cropped slide figures where clearer than a
  redraw (recommend yes).
- **Colour / print** — colour-first screen, print-safe (callouts distinguished
  by icon *and* label, diagrams legible in greyscale).

Recompute the frontier after each round. Stop when nothing is left unasked, then
present a short written plan (Goal / Constraints / Structure / Deliverables /
Verification) and get an explicit yes.

### 4. Scaffold the Typst project

Create in the user's chosen directory:

```
<proj>/
├── main.typ            # config + title + "how to use" + TOC + part dividers + includes
├── template.typ        # copy references/template.typ  (styles, callouts, theorem envs, worked/algo/practice)
├── diagrams.typ        # copy references/diagrams.typ   (CeTZ/cetz-plot/fletcher builders)
├── figs/               # cropped source screenshots
├── coverage.md         # source page -> section ledger
├── sections/NN-*.typ   # one file per Part (split at ~700 lines)
├── scratchpad/verify/  # python recompute scripts (not shipped)
├── out.pdf             # compiled
└── README.md           # package list, build command, font note
```

Copy `references/template.typ` and `references/diagrams.typ` (proven on Typst
0.15.x), adapt palette, header text and fonts, then run
`bash <skill>/scripts/sync-versions.sh <proj>`. Write `main.typ`
from `references/main-skeleton.typ`.

### 5. Verify numerics

For each source with worked problems, write `scratchpad/verify/<part>.py` that
recomputes every example (perceptron epochs, gradient steps, matrix products,
recall vectors, whatever the domain needs). Run it. Use its output as the
source of truth for the prose. `references/verify-example.py` is a worked
sample (neural-network numerics) to pattern-match against.

### 5b. Source screenshots

Wherever a source slide diagram, table or equation image explains better than a
redraw, screenshot it: render the page (`pdftoppm`), Read the PNG to pick the
crop box, crop tight (no slide chrome), save in `figs/`, and embed as
`#figure(image("figs/..."), caption: [...#sref[Lecture N, slide M]])`. Redraw
only if the source image is blurry or cluttered. Commands in
`references/typst-cookbook.md` > Screenshots. Ask about screenshots in the grill.

### 6. Build the sections

**Format contract (hard).** Notes are labelled blocks, never walls of text.
Read `references/topic-example.typ` and copy its shape for every topic.

- **Headings:** H2 per topic, H3 per subtopic (why / definition / types /
  steps / formula / comparison / example / pitfalls), H4 for cases. At most
  ~150 words under any heading.
- **Default block per piece of information:** terms = `definition` box;
  properties/rules/conditions = bullets (one idea each, <= 2 lines);
  procedures = numbered steps; contrasts, states, parameters, costs = tables;
  key formulas = `keyform` (every symbol explained); structure/flow/timing =
  diagram or source screenshot; numbers = `worked`; traps = `pitfall`/`tip`.
- **No paragraph walls:** a paragraph is <= 3 lines and rare. If a paragraph
  lists things, make it bullets; if it compares things, make it a table.
- **Source refs:** one `sref` per topic (in the definition or a caption), never
  per sentence.
- **Spine per topic** (skip only what truly does not exist): intuition (1-3
  lines) > definition/formula boxes > method steps > worked examples (every
  source problem + 2 extra) > pitfalls > practice (3-5).
- **Coverage:** every source slide is accounted for (see Gates below). Go
  slide cluster by slide cluster; each cluster becomes at least one H3.

**Gates, both must pass before delivery:**
`python3 <skill>/scripts/coverage-check.py <proj>` (keep `coverage.md`: one row
per source page: `| file.pdf | page | topic | section file or skip: reason |`) and
`python3 <skill>/scripts/structure-check.py <proj>` (headings every ~150 words,
paragraphs short, boxes, list/table items and figures per 1000 words). On
failure, restructure the section; never loosen the thresholds. Writer agents run
`structure-check.py` on their own file before reporting.

End-matter Part: master formula sheet (showybox cards), comparison matrices
(`tablem`), pitfall index (numbered, body callouts point here), symbol
glossary, a "how to attack a problem" table + `fletcher` decision flowchart,
and the practice answer key (final answers only, keyed by topic).

Wire the end-matter with `xref` / `backlink` (hard rule 6): every answer-key
entry links to its question and back, every pitfall-index entry links to its
body callout and back, every formula card links to where it was first derived
and back. Any forward mention in the section prose gets the same treatment.

Compile after each section: `typst compile main.typ out.pdf`. First compile
downloads the packages (needs network once). Fix every error and warning before
moving on. Read `references/typst-cookbook.md` for the syntax traps.

### 7. Review pass — density and gaps

Run both gates first. Then render a sweep of pages to PNG and actually look. Any
page that reads as a block of text, or lacks visible separation (headings,
boxes, tables, spacing), is a defect: restructure it.
`typst compile --pages A-B main.typ "/tmp/rev/p-{p}.png" --ppi 90`

- No page should be more than ~20% empty at the bottom from a block that jumped
  whole. If chapters are forcing page breaks, remove the `pagebreak` from the
  level-1 heading show rule (the template ships without it).
- Tighten `par(leading:, spacing:)` and showybox `inset` / `spacing` if the
  layout feels loose; loosen if it is cramped.
- Every `#figure` renders, nothing clipped, body never scrolls horizontally.
- Margins symmetric, text column fills the page (no wide empty side margin);
  screenshots sharp and cropped tight.
- Every `xref` mention is visibly linked and lands on the right target; every
  target shows its `backlink` ↩ marker(s) and each returns to a distinct spot.
  A dangling `#link(<label>)` warns at compile — rule 3 already fails the build.
- Print one page in greyscale mentally: callouts still tell apart by icon+label.

### 8. Deliver

`SendUserFile` the compiled PDF. Report: page count, clean-compile confirmation,
the section list, and where the `.typ` sources + verify scripts live. Write the
README (package table with pinned versions, `typst compile` command, font note:
needs *New Computer Modern* / *New Computer Modern Math*).

## Diagrams

**Gallery first.** `references/gallery/` holds compile-verified `demo-*`
functions (exact imports, versions, gotchas in comments). Read the relevant
file, copy the demo, adapt. Do not guess a package API when a demo exists.

| File | Covers |
|---|---|
| `gallery/ml-quantum-math.typ` | quill circuits, Bloch sphere (czbloch/tybloch), lilaq plots/heatmap/contour, cetz-plot, Venn, equation annotation (mannot, equate), CNN (neural-netz), pipelines (neural-viz), confusion matrix, MLP/transformer/backprop (fletcher), Graphviz DAG, probability trees |
| `gallery/systems-hw.typ` | bytefield (packet/register), blockcell, network topology, CPU datapath (circuiteria), circuits (zap), timing (digidraw), K-map, truth table, DFA (finite), stack/heap, 5-stage pipeline, cache lookup, memory hierarchy, page walk, MPI send/recv + allreduce, process states, TCP handshake |
| `gallery/sde-algo-layout.typ` | sequence (chronos), ER (pintorita), UML (mastermind), Gantt (timeliney), trees (tdtr/arborly), inference/Fitch proofs, pseudocode (lovelace/algorithmic), code with highlights (codly), margin notes (marginalia), text wrap, sub-figures, hand-drawn look, SDLC models, git graph, memory pictures, BFS, call stack, big-O plot |

If the concept is not in the gallery, search the package catalog (cookbook),
build a minimal demo in a scratch file, and only then use it. Add a new
verified demo to the gallery when it works and is reusable.

Fallback order when no demo fits:

 (1) a domain package from the
catalog (quill, czbloch, finite, chronos, timeliney, circuiteria, bytefield,
neural-netz, ...); (2) `fletcher` for node-arrow structure; (3) `cetz` +
`cetz-plot` or `lilaq` for geometry and plots; (4) a cropped source screenshot.
Use colour sparingly and consistently, label directly on the figure, caption
every figure with what to notice, not what it is.

## Packages: always latest, never pinned by hand

Run `bash <skill>/scripts/sync-versions.sh <proj>` right after scaffolding and
again before delivery. It rewrites every `@preview/<pkg>:<ver>` import to the
newest registry version. Then compile. If a major bump breaks the build, read
that package's README in `~/.cache/typst/packages/preview/<pkg>/<ver>/` and fix
the call (do not pin back unless the fix takes more than 2 attempts; then note
the pin in README.md). The shipped templates were last verified on: codly 2.x
(new `codly.*` API), cetz 0.5.x, Typst 0.15.

Baseline (swap or add per recon): `cetz`, `cetz-plot` (or `lilaq`), `fletcher`,
`great-theorems` + `rich-counters`, `showybox` (key-formula cards only),
`codly` + `codly-languages`, `physica`, `hydra`, `tablem`.

## Files in this skill

- `references/typst-cookbook.md` — **read first.** Versions, exact import/setup
  lines, and the Typst syntax-trap list.
- `references/template.typ` — proven styles + `notes-conf` + all helpers
  (`intuition`, `tip`, `watch`, `pitfall`, `remember`, `derivation`,
  `definition`, `theorem`, `property`, `lrule`, `worked`, `practice`, `algo`,
  `keyform`, `sref`, `xref`, `backlink`, `part`). Copy verbatim.
- `references/diagrams.typ` — proven CeTZ/cetz-plot/fletcher builders
  (`layered-net`, `neuron`, `act-plot`, `decision-boundary`, `signal-flow-bpn`,
  `gaussian-kernel`, `delay-line`, `pattern-grid`, `nm`). Copy verbatim; add
  domain-specific builders alongside.
- `references/topic-example.typ` — one correctly structured topic; copy its shape.
- `scripts/coverage-check.py`, `scripts/structure-check.py` — delivery gates.
- `references/main-skeleton.typ` — starter `main.typ` (title, how-to-use, TOC,
  part dividers, includes).
- `references/verify-example.py` — sample numeric-verification script.
- `scripts/extract.sh` — `lit parse` batch wrapper.
- `references/gallery/*.typ` — verified diagram demos (see Diagrams).
- `scripts/sync-versions.sh` — bump all `@preview` imports to latest.
