// ===========================================================================
//  ONE TOPIC, CORRECTLY STRUCTURED. Copy this shape for EVERY topic.
//  The page must read as separate labelled blocks, never as paragraphs.
//  Rules: H2 per topic, H3 per subtopic, <= 150 words under any heading,
//  bullets are one idea and <= 2 lines, paragraphs <= 3 lines (rare),
//  sref ONCE per topic (end of the Definition or in a caption), not per sentence.
// ===========================================================================
#import "template.typ": *

== Cache coherence

#definition("Cache coherence")[
  All caches see one consistent value for each memory location.
  #sref[Unit I, slides 55-60]
]

=== Why it is needed
- Each core caches memory lines privately.
- A write in one cache makes other copies *stale*.
- Without a protocol, two cores read different values for one address.

=== Protocol states (MSI)
#table(
  columns: (auto, 1fr, 1fr),
  [State], [Meaning], [Allowed ops],
  [Modified], [Only valid copy, dirty], [read, write],
  [Shared], [Clean, other copies may exist], [read],
  [Invalid], [Line unusable], [none],
)

=== Snooping vs directory
#table(
  columns: (auto, 1fr, 1fr),
  [], [Snooping], [Directory],
  [Traffic], [Broadcast on bus], [Point-to-point],
  [Scales to], [~8-16 cores], [100s of cores],
  [Cost], [Bus bandwidth], [Directory storage],
)

=== Write-invalidate steps
+ Core A writes line X.
+ A broadcasts an *invalidate* for X.
+ Other caches mark X *Invalid*.
+ A's copy becomes *Modified*.

#keyform[
  $ "miss rate" = "misses" / "accesses" $ where #h(0.3em) misses $<=$ accesses.
]

#figure(
  rect(width: 70%, height: 3cm, fill: c-bg-soft)[#align(center + horizon)[diagram placeholder]],
  caption: [MSI transitions on read/write hits and misses.],
)

=== Worked example
#worked("Count invalidations",
  given: [Cores A, B share X in Shared; A writes X once.],
  find: [Number of invalidate messages.],
  [Only B holds another copy, so one invalidate is sent.],
  answer: [1 message],
)

#pitfall[Coherence is not consistency: it orders writes to *one* address only.]
#tip[Exam: always state the state of *every* cache after each step.]

#practice(([Define coherence in one line.], [Compare snooping and directory in 3 points.]), tag: "Coherence")
