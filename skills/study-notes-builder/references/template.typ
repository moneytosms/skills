// ============================================================================
//  template.typ — styles, callouts, theorem environments, structural helpers
//  study-notes-builder skill — generic notes styles
//  Typst 0.15.1
// ============================================================================

#import "@preview/great-theorems:0.1.2": *
#import "@preview/rich-counters:0.2.2": *
#import "@preview/codly:2.0.0" as codly
#import "@preview/codly-languages:0.1.10": codly-languages
#import "@preview/showybox:2.0.4": showybox
#import "@preview/hydra:0.6.3": hydra
#import "@preview/physica:0.9.8" as phys
#import "@preview/tablem:0.3.0": tablem

// ---------------------------------------------------------------------------
//  Palette  (colour-first, but every callout also carries an icon + label,
//  and diagram code varies dash/weight so greyscale still reads)
// ---------------------------------------------------------------------------
#let c-ink      = rgb("#22252b")
#let c-accent   = rgb("#2f5d8a")   // muted blue
#let c-accent2  = rgb("#3b7a78")   // teal
#let c-good     = rgb("#3f7d4e")   // green
#let c-warn     = rgb("#a8741a")   // amber
#let c-bad      = rgb("#b04a3f")   // red
#let c-muted    = rgb("#5c5c6e")
#let c-rule     = rgb("#d8d8e0")
#let c-bg-soft  = rgb("#f6f7f9")

// ---------------------------------------------------------------------------
//  Numbered-equation counter that resets each chapter (level-1 heading)
// ---------------------------------------------------------------------------
#let eqn-counter = counter("eqn-per-chapter")

// ===========================================================================
//  MAIN CONFIGURATION  —  applied in main.typ via  #show: notes-conf
// ===========================================================================
#let notes-conf(body) = {
  set page(
    paper: "a4",
    margin: (x: 2.3cm, y: 2.4cm),   // symmetric: no left/right page drift
    header-ascent: 1.1em,
    header: context {
      set text(size: 8.5pt, fill: c-muted)
      grid(
        columns: (1fr, auto),
        align: (left, right),
        hydra(1),
        [Soft Computing Notes],
      )
      v(-0.55em)
      line(length: 100%, stroke: 0.5pt + c-rule)
    },
    footer: context {
      set text(size: 9pt, fill: c-muted)
      align(center, counter(page).display("1"))
    },
  )

  set text(
    font: ("New Computer Modern", "Libertinus Serif"),
    size: 10.5pt,
    fill: c-ink,
    lang: "en",
  )
  set par(justify: true, leading: 0.62em, spacing: 0.95em)

  // ---- headings ----------------------------------------------------------
  set heading(numbering: "1.1")
  show heading: set text(fill: c-ink)
  show heading.where(level: 1): it => {
    eqn-counter.update(0)
    block(above: 1.8em, below: 0.9em, breakable: false, {
      set text(size: 18pt, weight: "bold", fill: c-accent)
      if it.numbering != none [#counter(heading).display() #h(0.5em)]
      it.body
      v(0.35em)
      line(length: 100%, stroke: 1pt + c-accent)
    })
  }
  show heading.where(level: 2): it => block(above: 1.15em, below: 0.55em, breakable: false, {
    set text(size: 13pt, weight: "bold", fill: c-accent2)
    if it.numbering != none [#counter(heading).display() #h(0.4em)]
    it.body
  })
  show heading.where(level: 3): it => block(above: 0.9em, below: 0.45em, breakable: false, {
    set text(size: 11pt, weight: "bold", fill: c-ink)
    if it.numbering != none [#counter(heading).display() #h(0.35em)]
    it.body
  })

  // ---- equations: unnumbered (these are study notes; equations are
  //      referred to by name/context, never by number) -----------------
  set math.equation(numbering: none)

  // ---- links / refs ---------------------------------------------------
  show link: set text(fill: c-accent)
  show ref: set text(fill: c-accent)

  // ---- lists --------------------------------------------------------
  set list(indent: 0.6em, spacing: 0.75em)
  set enum(indent: 0.6em, spacing: 0.75em, numbering: "1.")

  // ---- tables: light, book-style -----------------------------------
  set table(
    stroke: (x, y) => (
      top: if y == 0 { 1pt + c-ink } else if y == 1 { 0.7pt + c-ink } else { 0pt },
      bottom: 0pt,
    ),
    inset: (x: 0.7em, y: 0.55em),
    align: left + horizon,
  )
  show table.cell.where(y: 0): set text(weight: "bold")

  // ---- figures -----------------------------------------------------
  show figure.caption: set text(size: 9.5pt, fill: c-muted)
  set figure(gap: 0.9em)

  // ---- code / algorithm blocks (codly) ---------------------------
  show: codly.lang-set_(languages: codly-languages)
  show: codly.set_(padding: 0.55em, radius: 4pt, gutters: ())
  show: codly.line-set_(fill: c-bg-soft)
  show raw.where(block: true): codly.new

  // ---- theorem family (great-theorems) -------------------------
  show: great-theorems-init

  body
}

// ===========================================================================
//  THEOREM-FAMILY BLOCKS
//  rich-counter shared by all so they number chapter.n in one sequence
// ===========================================================================
#let _mathcnt = rich-counter(identifier: "sc-mathblocks", inherited_levels: 1)

#let _framed(accent, fill, it) = showybox(
  frame: (border-color: accent, title-color: accent, body-color: fill,
          thickness: (left: 2.5pt, rest: 0.6pt), radius: 3pt, inset: 0.75em),
  breakable: true, spacing: 0.85em, above: 0.85em, below: 0.85em,
  it,
)

#let definition = mathblock(blocktitle: "Definition", counter: _mathcnt,
  titlix: title => [ (#title).])
#let theorem = mathblock(blocktitle: "Theorem", counter: _mathcnt,
  titlix: title => [ (#title).])
#let property = mathblock(blocktitle: "Property", counter: _mathcnt,
  titlix: title => [ (#title).])
#let lrule = mathblock(blocktitle: "Learning Rule", counter: _mathcnt,
  titlix: title => [ — #title.])
#let proof = proofblock()

// ===========================================================================
//  CALLOUTS  (light left-rule asides; use sparingly)
// ===========================================================================
// Light aside: coloured bold lead-in + thin left rule. No fill, no icon, no box.
// Use sparingly; plain prose / bold / indentation is usually enough.
#let _aside(accent, label, body) = block(
  width: 100%, above: 0.9em, below: 0.9em, inset: (left: 0.9em, y: 0.15em),
  stroke: (left: 1.8pt + accent),
)[#text(fill: accent, weight: "bold")[#label.] #body]

#let intuition(body, title: "Intuition") = _aside(c-accent2, title, body)
#let tip(body, title: "Exam tip") = _aside(c-good, title, body)
#let watch(body, title: "Watch out") = _aside(c-warn, title, body)
#let pitfall(body, title: "Pitfall") = _aside(c-bad, title, body)
#let remember(body, title: "Remember") = _aside(c-accent, title, body)
#let mini(body, title: "Example") = _aside(c-muted, title, body)
#let derivation(body, title: "Derivation (skippable)") = _aside(c-muted, title, text(size: 0.95em, body))

// ===========================================================================
//  WORKED EXAMPLE  —  identical Given / Find / Solution / Answer skeleton
// ===========================================================================
#let worked(
  title,
  given: none,
  find: none,
  body,
  answer: none,
  diverges: none,
) = block(
  width: 100%, above: 1em, below: 1em, inset: (left: 1em, y: 0.5em),
  stroke: (left: 2.2pt + c-good), fill: c-bg-soft, breakable: true,
  {
    set math.equation(numbering: none)
    text(fill: c-good, weight: "bold")[Example — #title]
    parbreak()
    if given != none [ *Given.* #given #parbreak() ]
    if find != none [ *Find.* #find #parbreak() ]
    body
    if answer != none [ #parbreak() #text(fill: c-good)[$arrow.r$ *Answer.*] #answer ]
    if diverges != none {
      parbreak()
      text(size: 9pt, fill: c-warn)[_Differs from the source:_ #diverges]
    }
  },
)

// ===========================================================================
//  PRACTICE BLOCK  —  numbered questions; answers keyed <chapter>.<n> in App. G
// ===========================================================================
#let practice(items, tag: none) = block(width: 100%, above: 1em, below: 1em, {
  text(fill: c-accent, weight: "bold")[Practice#if tag != none [ — #tag]]
  set enum(numbering: "P1.")
  for it in items [+ #it]
})

// ===========================================================================
//  Small structural helpers
// ===========================================================================
// margin note for textbook §-refs and divergence remarks
#let sref(body) = text(size: 8.5pt, fill: c-muted, style: "italic")[ (#body)]

// internal cross-reference — forward hyperlink to a labelled target elsewhere
// in the notes (a heading, appendix, worked example, formula card). Label the
// call site too, so the target can link back.  Usage:
//   ... derived in #xref(<app-c>)[Appendix C]. <q-bpn-appc>
// then at the target heading:
//   == Appendix C — BPN derivation <app-c> #backlink(<q-bpn-appc>)
#let xref(target, body) = link(target, text(fill: c-accent, body))

// subtle "return" marker placed at a cross-reference target, linking back to
// the spot that referred here. Repeat it once per referring site:
//   <app-c> #backlink(<q1>)#backlink(<q2>)
#let backlink(source) = super(link(source, text(size: 0.8em, fill: c-muted)[ ↩]))

// numbered-step algorithm container
#let algo(title, steps) = block(width: 100%, above: 0.9em, below: 0.9em, {
  text(weight: "bold")[#title]
  set enum(numbering: "1.")
  for s in steps [+ #s]
})

// key-formula highlight strip
#let keyform(body) = block(
  width: 100%, inset: 0.8em, radius: 3pt,
  fill: c-bg-soft, stroke: (left: 2.5pt + c-accent),
  body,
)

// part divider page
#let part(n, title, blurb) = {
  pagebreak(weak: true)
  set page(header: none)
  v(1fr)
  align(center, {
    text(size: 13pt, fill: c-muted, tracking: 3pt)[PART #n]
    v(0.6em)
    text(size: 30pt, weight: "bold", fill: c-accent)[#title]
    v(1em)
    block(width: 70%, {
      set text(size: 11pt, fill: c-muted)
      set par(justify: true)
      blurb
    })
  })
  v(1.4fr)
  pagebreak(weak: true)
}
