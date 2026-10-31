// ============================================================================
//  main.typ  —  starter for a study-notes-builder project
//  Build:  typst compile main.typ out.pdf
//  Fonts:  needs "New Computer Modern" / "New Computer Modern Math"
//  First compile downloads the @preview packages (needs network once).
// ============================================================================

#import "template.typ": *

#show: notes-conf

// ---------------------------------------------------------------------------
//  Title page
// ---------------------------------------------------------------------------
#set page(header: none, footer: none)
#v(1fr)
#align(center, {
  text(size: 13pt, fill: c-muted, tracking: 4pt)[SUBJECT NAME]
  v(0.8em)
  text(size: 32pt, weight: "bold", fill: c-accent)[Notes Title\ Second Line]
  v(1.2em)
  line(length: 45%, stroke: 1pt + c-accent)
  v(1.2em)
  block(width: 78%, {
    set text(size: 11pt, fill: c-muted)
    set par(justify: true)
    [One sentence on scope. Aligned to TEXTBOOK or SYLLABUS.]
  })
})
#v(1.6fr)
#align(center, text(size: 9pt, fill: c-muted)[Compiled with Typst])
#pagebreak()

// ---------------------------------------------------------------------------
//  How to use  +  Table of contents
// ---------------------------------------------------------------------------
#set page(header: none)
// Optional, 2-3 sentences max: what the notes cover and how to read them.
// No legend of box types: definition, formula, example, pitfall are self-evident.

#v(1em)
#outline(title: [Contents], indent: auto, depth: 2)

// ---------------------------------------------------------------------------
//  Body  —  one #include per Part; #part(...) draws a divider page
// ---------------------------------------------------------------------------
#part("I", "Foundations",
  [Short blurb: what this Part covers and why it comes first.])
#include "sections/01-foundations.typ"

#part("II", "Core Topics",
  [Short blurb.])
#include "sections/02-core.typ"

#part("III", "Reference",
  [Formula sheet, comparison matrices, pitfall index, symbol glossary,
   problem-attack guide, practice answer key.])
#include "sections/03-appendices.typ"
