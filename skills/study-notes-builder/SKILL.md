---
name: study-notes-builder
disable-model-invocation: true
description: Build a single detailed, exam-oriented PDF of study notes from source material (lecture PDFs/PPTs, existing notes, a syllabus, or a topic list) with Typst. Per topic: intuition, boxed definitions/formulas, algorithm steps, every source problem plus extra verified worked examples, pitfalls, practice. Exam end-matter (formula sheet, comparison tables, pitfall index, glossary, answer key). Coverage ledger gates delivery so no slide is missed. No length target, no filler. Runs recon, grill, verify-numerics, build, coverage audit, review and delivers a compiled PDF plus modular .typ sources.
---

# Study Notes Builder

Turn whatever the user hands you (PDFs, PPTX, images, a syllabus, a topic list)
into one PDF of **detailed, exam-ready study notes**: the document a student
could study from alone, the night before, without opening the slides. Detailed
beats short. Scannable beats flowing. Every fact in the source is in the notes,
plus what is needed to actually solve the problems.

Built with **Typst**. Source extraction uses **`lit`** (liteparse) when
installed, else the Read tool.

## When this applies

Trigger phrases: "make notes / cheatsheet / revision notes / study guide for
<subject>", "turn these PPTs into notes", "notes from this syllabus". Not this
skill: a single short explainer, editing an existing prose doc, one conceptual
question.

## Completeness and layout (the part that matters most)

**Completeness contract.** The notes cover everything the sources cover.

1. **Nothing silently dropped.** Every slide/page of every source ends up in
   `coverage.md` mapped to the section that covers it, or marked `skip: <reason>`
   (title slides, agendas, "thank you", exact duplicates). Any other skip needs
   the user's OK. Duplicates across sources are merged, but each unique fact,
   formula, definition, example, table, figure and caveat survives.
2. **No page-count target.** Length is whatever complete coverage takes.
   Never compress to hit a size, never pad to reach one. Coverage is judged
   per item (every slide, formula, definition, example, figure, table), not per
   page. `scripts/coverage-check.py` reports the ratio for information only.
3. **Complete first, then augment.** Cover the source fully, then fill gaps the
   source assumes (within the scope the user set). Never trade source content for
   brevity or flow.

**Structure.** Notes are reference material you scan, not an essay you read.

4. **Dense heading hierarchy:** Part > Chapter > Topic (H2) > Subtopic (H3), H4
   for cases/variants. Every concept, term, algorithm, formula group and
   problem type gets its own heading so it is in the TOC and findable in 5
   seconds. Max ~150 words under any heading before the next one. Every term
   the source defines or uses as jargon gets a `definition` box, in a glossary
   fashion, at first use.
5. **Per-topic spine** (in syllabus order). Each part carries different
   information, so none restates another; skip a part only when the topic has
   nothing for it:
   1. **Intuition**: 1-3 lines on what it is and why, only where the idea is
      not obvious from the definition. No stories or analogies that run long.
   2. **Math**: `definition` / `theorem` / `property` / `keyform` boxes (every
      symbol explained), derivations with every step shown.
   3. **Algorithm / method**: numbered steps in `algo`, general enough to solve
      any instance of the problem type.
   4. **Worked examples**: every source problem reproduced, plus **2 extra**
      solved problems per topic (different shapes, edge cases). All verified.
   5. **Pitfalls**: bullets, exam-trap focused.
   6. **Practice**: 3-5 questions per topic (mixed: conceptual, compare, derive,
      numeric), answers in the key.
   Use **tables** for every contrast, classification, parameter list, cost or
   complexity comparison, and **bullets** for properties, rules and conditions.
   **Diagrams** or source screenshots for anything with a shape. If a sentence
   repeats something already on the page, delete it.
6. **Bullets and tables over paragraphs.** Anything list-like is bullets,
   contrasts are tables, sequences are numbered steps. Paragraphs max ~3 lines,
   only where bullets would lose meaning. A page that is mostly unbroken prose
   is a defect.
7. **Boxes are for what you revise from:** definitions, key formulas/theorems,
   worked examples, pitfalls, exam points. Use them freely for those, not for
   decoration. No icons, emoji, or legend.
8. **No filler.** No stories, anecdotes, motivation, "imagine...", "it is
   important to note", transitions, or sections that restate earlier ones. A
   concept map only where topics genuinely depend on each other.
9. **Layout:** symmetric margins, single centred text column filling the page,
   comfortable leading, muted colours with one or two accents. No wide empty
   side margin, no half-empty pages from forced page breaks.
10. **Diagrams are a feature.** Every concept with a shape (architecture, state
    machine, timeline, geometry, protocol, data layout, dataflow) gets a
    specific diagram (see "Diagrams"). Prefer expressive over generic
    box-and-arrow.
11. **Source screenshots are welcome** wherever a slide diagram, table or
    equation image explains better than a redraw. Crop tight, embed as
    `#figure(image(...), caption: [...])` with a short caption and a source
    reference. Redraw only if blurry or cluttered. See the cookbook for crop
    commands.
12. **Augment so every problem type can be solved properly.** Cover the source
    fully, then add what it assumes or skips (within the scope the user set in
    the grill): foundations it relies on, missing derivation steps, the general
    method for each problem type, edge cases, units, common error checks. All
    numbers verified.
13. **Exam end-matter** (default yes, user can drop): master formula sheet,
    comparison matrices (`tablem`), pitfall index, symbol glossary, "how to
    attack a problem" table with a `fletcher` decision flowchart, practice
    answer key (full solutions). Wired with `xref` / `backlink`.

## Hard rules

1. **Ask before building.** Do not write sections until the user answered the
   intake questions (step 3) and approved the plan.
2. **Verify every number.** Recompute every worked numerical example in a
   throwaway script (`scratchpad/verify/*.py`) before writing its prose. Where
   it diverges from the source, say so inline.
3. **Zero-warning compile gate.** `typst compile main.typ out.pdf` exits 0 with
   no warnings. Treat any warning as a defect.
4. **Coverage and structure gates.** Both must pass before delivery:
   `python3 <skill>/scripts/coverage-check.py <proj>` (every source page mapped
   or approved-skipped) and `python3 <skill>/scripts/structure-check.py <proj>`
   (headings every ~150 words, paragraphs mostly <= 60 words, boxes, bullets/
   table rows and figures per 1000 words above minimums). A failing structure
   check means the section is prose: restructure into headings, definitions,
   bullets, tables and diagrams, do not tune the thresholds.
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
  synthesis: teaching order, which standard syllabus topics are absent. Each
  digest agent also writes its rows of `coverage.md`: one row per source page
  (`source | page | topics on it | target section`), planned in advance.
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

Cover: coverage (default: everything in the sources, no length target); purpose and notation (exam, textbook, cheat
sheet vs teaching notes); worked-example treatment (recommend: recompute every source problem + 2 extra solved per topic + 3-5 practice per topic with answer key); end-matter (recommend: all); **visual investment and
which concepts deserve custom diagrams (propose packages from recon)**;
**which source screenshots to include**; chapter outline (propose, confirm);
optional practice/answer key; deliverable form. Then present a short plan
(Goal / Constraints / Structure / Deliverables / Verification) and get an
explicit yes.

### 4. Scaffold

```
<proj>/
├── coverage.md     # source page -> section ledger (checked by script)
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
numbers, its `coverage.md` rows, and the Completeness and layout rules above).
Give each its section file only. Each must cover every page in its rows and
report back the source pages it covered and the page count it produced. Writer
agents must be told: headings every ~150 words, definitions for every term,
bullets and tables by default, a diagram per concept with a shape, paragraphs
<= 3 lines; run `structure-check.py` on their file before reporting. Compile
after each section; fix every warning. Helpers available in `template.typ`:
`worked`, `keyform`, `definition`/`theorem`/`property`, `intuition`/`tip`/
`watch`/`pitfall`/`remember` (light left-rule asides), `algo`
(plain numbered list), `practice`, `sref` (inline source ref), `xref`,
`backlink`, `part`.

End-matter (rule 13): formula sheet, comparison tables (`tablem`),
pitfall index, glossary, problem-attack guide, answer key.

### 7. Review and clean

Run `python3 <skill>/scripts/coverage-check.py <proj>` and
`python3 <skill>/scripts/structure-check.py <proj>` first; fix every unmapped
page and every prose-heavy file.
Also confirm: every topic follows the spine (intuition, math, method, worked examples incl. the 2 extras, pitfalls, practice), no fact stated twice, tables for every contrast, end-matter present. Then render pages to PNG and actually look (`typst compile --pages A-B main.typ
"/tmp/rev/p-{p}.png" --ppi 90`). Check against the layout rules, as a checklist:

- Is every topic findable by heading, in the skeleton shape? Any page that is
  mostly unbroken prose? Restructure into bullets, tables, boxes.
- Spot-check 10 random source slides: is each one's content in the notes?
- Margins symmetric, text fills the page, no half-empty pages, no clipped
  figures, screenshots sharp and cropped tight.
- Every diagram specific and legible, not a generic grey box chain.
- Links land on the right targets; numbers match the verify scripts.
- Repetition, filler, stories, chapter intros/summaries, "It is important to
  note": delete.

Fix, recompile, re-look. Repeat until clean.

### 8. Deliver

Send the PDF. Report page count, clean-compile confirmation, section list, where
sources and verify scripts live. Include the coverage-check result. Next step: the single command to rebuild
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
- `scripts/structure-check.py` — fails prose-heavy sections (heading density, long paragraphs, boxes, list/table items, figures per 1000 words).
- `scripts/coverage-check.py` — validates `coverage.md` against source page counts (every page mapped or skipped).
