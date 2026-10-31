---
name: study-notes-builder
disable-model-invocation: true
description: Build a single polished PDF of readable, well-connected study notes from source material (lecture PDFs/PPTs, existing notes, a syllabus, or a topic list) with Typst. Prose-first textbook feel, inline math, strong domain diagrams (searches Typst packages), source screenshots, verified worked examples. Runs parallel recon, grill, verify-numerics, build, review and delivers a compiled PDF plus modular .typ sources.
---

# Study Notes Builder

Turn whatever the user hands you (PDFs, PPTX, images, a syllabus, a topic list)
into one cohesive PDF of **readable, well-connected study notes**: a textbook /
lecture-notes read that is easy on the eyes. Mostly flowing prose with bullets
and inline math, strong diagrams, and verified worked examples placed right
next to the concept they illustrate.

Built with **Typst**. Source extraction uses **`lit`** (liteparse) when
installed, else the Read tool.

## When this applies

Trigger phrases: "make notes / cheatsheet / revision notes / study guide for
<subject>", "turn these PPTs into notes", "notes from this syllabus". Not this
skill: a single short explainer, editing an existing prose doc, one conceptual
question.

## Voice and layout (the part that matters most)

Notes are a connected explanation, not a stack of widgets.

1. **Prose is the default.** Explain in paragraphs, use bullets for genuine
   lists, inline math for symbols, display math for key equations. A reader
   should be able to read a chapter top to bottom as one argument.
2. **Connect everything.** Every chapter opens with 2-4 sentences: what problem
   it solves, how it follows from the previous chapter, what it sets up. Between
   sections, say why the next idea is needed ("this fails when..., so we...").
   Open each Part with a small concept map (fletcher/diagraph) when topics
   depend on each other.
3. **Boxes are rare.** Only these may be boxed or ruled off: worked examples,
   the few key formulas/definitions worth memorising, and genuine pitfalls.
   Everything else is plain text, bold lead-ins, headings, or indentation.
   Budget: if a page has more than ~1 box-like element, merge or demote. Never
   box a paragraph just to make it look structured. No icons, emoji, or legend.
4. **No rigid per-topic template.** There is no mandatory
   intuition → algorithm → example → pitfall → practice sequence. Let the
   topic and source decide: a proof-heavy topic is mostly derivation, a
   conceptual one is mostly prose and a diagram, a numeric one leads with an
   example. Vary the shape; skip parts that add nothing.
5. **Examples live inline**, right after the idea they illustrate. Practice
   questions and an answer key are optional: include only if the user wants
   them (default: end-of-Part short practice set + answer key).
6. **Layout:** symmetric margins (never mirrored inside/outside), single
   centred text column filling the page, comfortable leading, muted colours
   with one or two accents. No wide empty side margin. No per-chapter page
   breaks that leave half-empty pages.
7. **Diagrams are a feature.** Prefer a specific, expressive diagram over a
   generic box-and-arrow one (see "Diagrams" below). Every non-trivial concept
   that has a shape (architecture, state machine, timeline, geometry, protocol,
   data layout) should get one.
8. **Screenshots from the source are welcome** wherever a source figure, slide
   diagram, table or equation image explains better than a redraw. Crop tight,
   embed as `#figure(image(...), caption: [...])` with a short caption and a
   source reference. Redraw only if the source image is blurry, cluttered, or
   would need heavy edits. See the cookbook for the crop commands.

## Hard rules

1. **Ask before building.** Do not write sections until the user answered the
   intake questions (step 3) and approved the plan.
2. **Verify every number.** Recompute every worked numerical example in a
   throwaway script (`scratchpad/verify/*.py`) before writing its prose. Where
   it diverges from the source, say so inline.
3. **Zero-warning compile gate.** `typst compile main.typ out.pdf` exits 0 with
   no warnings. Treat any warning as a defect.
4. **Augment, don't just transcribe.** Fill gaps the source assumes, within the
   scope the user set.
5. **Read `references/typst-cookbook.md` before writing any `.typ`** (versions,
   syntax traps, package catalog, screenshot commands).
6. **Search for packages before drawing.** See step 3 (Recon). Do not default to
   the baseline stack when a domain package exists.
7. **Internal references are live links** (`xref` / `backlink` in
   `template.typ`) when the notes point to another part of themselves ("see
   Appendix C", "the recall formula above"). Link both directions only where
   the target is a real jump (appendices, formula sheet, answer key); in-flow
   mentions need just the forward `xref`.

## Workflow

### 1. Intake

List what the user gave. If `lit` exists, batch-extract:
`bash <skill>/scripts/extract.sh "<src_dir>" "<out_dir>"`; else Read the files.
Topic-only request: knowledge-driven, skip digest.

### 2. Recon, in parallel (subagents)

Launch these concurrently (single message, multiple Agent calls), each
read-only, each returning a short report with an explicit "nothing found" where
applicable:

- **Digest agent(s)**: one per source cluster. Per source: topic order, every
  formula, every worked numerical example (inputs + method), every figure worth
  screenshotting (page/slide number + what it shows), OCR quality. Then
  synthesis: teaching order, which standard syllabus topics are absent.
- **Package scout**: given the subject and the list of diagram-worthy concepts
  (e.g. Bloch sphere, MPI message flow, SDLC/Gantt, DFA, UML, circuits), search
  the Typst Universe index (cookbook "Package catalog") and `typst.app/universe`
  for packages that draw them. Return: package, latest version, one-line API
  sketch, and a minimal snippet it has compiled in a scratch file. Also report
  anything better than the baseline for tables, math annotation, plots
  (`lilaq`), margin notes.
- **Figure scout** (if sources are PDFs/slides): render candidate figure pages
  to PNG, report the crop box for each usable figure.

Synthesize into a draft outline before talking to the user.

### 3. Grill

Rounds of numbered questions with a recommended answer each; wait between
rounds. Format:

```
Q1 <title>: <body, options>
Recommended: <answer>
```

Cover: scope/augmentation depth; purpose and notation (exam, textbook, cheat
sheet vs teaching notes); worked-example treatment; **visual investment and
which concepts deserve custom diagrams (propose packages from recon)**;
**which source screenshots to include**; chapter outline (propose, confirm);
optional practice/answer key; deliverable form. Then present a short plan
(Goal / Constraints / Structure / Deliverables / Verification) and get an
explicit yes.

### 4. Scaffold

```
<proj>/
├── main.typ        # config + title + TOC + parts
├── template.typ    # copy references/template.typ
├── diagrams.typ    # copy references/diagrams.typ, add domain builders
├── figs/           # source screenshots
├── sections/NN-*.typ
├── scratchpad/verify/
└── out.pdf
```

Copy `template.typ` / `diagrams.typ` and adapt (palette, header text, fonts), then run `scripts/sync-versions.sh <proj>`.
`main.typ` from `references/main-skeleton.typ`.

### 5. Verify numerics

`scratchpad/verify/<part>.py` recomputes every example. Output is the source of
truth. `references/verify-example.py` is a sample.

### 6. Write, in parallel where independent

Parts with no dependency on each other can be written by parallel subagents
(each: the outline, the template, the cookbook, its sources, its verified
numbers, and the Voice rules above). Give each its section file only. Compile
after each section; fix every warning. Helpers available in `template.typ`:
`worked`, `keyform`, `definition`/`theorem`/`property`, `intuition`/`tip`/
`watch`/`pitfall`/`remember` (light left-rule asides, use sparingly), `algo`
(plain numbered list), `practice`, `sref` (inline source ref), `xref`,
`backlink`, `part`.

Optional end-matter (if the user wants it): formula sheet, comparison tables
(`tablem`), problem-attack guide, answer key.

### 7. Review and clean

Render pages to PNG and actually look (`typst compile --pages A-B main.typ
"/tmp/rev/p-{p}.png" --ppi 90`). Check against the Voice rules, as a checklist:

- Does it read as connected prose? Any chapter that is a stack of boxes?
  Box count per page, merge or demote.
- Margins symmetric, text fills the page, no half-empty pages, no clipped
  figures, screenshots sharp and cropped tight.
- Every diagram specific and legible, not a generic grey box chain.
- Links land on the right targets; numbers match the verify scripts.
- Generic phrasing and filler ("It is important to note", "In conclusion",
  summary paragraphs that restate the section): delete.

Fix, recompile, re-look. Repeat until clean.

### 8. Deliver

Send the PDF. Report page count, clean-compile confirmation, section list, where
sources and verify scripts live. Next step: the single command to rebuild
(`typst compile main.typ out.pdf`).

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
- `references/template.typ` — light styles + `notes-conf` + all helpers
  (`intuition`, `tip`, `watch`, `pitfall`, `remember`, `derivation`,
  `definition`, `theorem`, `property`, `lrule`, `worked`, `practice`, `algo`,
  `keyform`, `sref`, `xref`, `backlink`, `part`). Copy and adapt.
- `references/diagrams.typ` — proven CeTZ/cetz-plot/fletcher builders
  (`layered-net`, `neuron`, `act-plot`, `decision-boundary`, `signal-flow-bpn`,
  `gaussian-kernel`, `delay-line`, `pattern-grid`, `nm`). Copy verbatim; add
  domain-specific builders alongside.
- `references/main-skeleton.typ` — starter `main.typ` (title, how-to-use, TOC,
  part dividers, includes).
- `references/verify-example.py` — sample numeric-verification script.
- `scripts/extract.sh` — `lit parse` batch wrapper.
- `references/gallery/*.typ` — verified diagram demos (see Diagrams).
- `scripts/sync-versions.sh` — bump all `@preview` imports to latest.
