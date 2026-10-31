// Gallery C: software engineering, algorithms/data structures, proofs, layout/annotation.
// Every demo-* is self-contained and compile-verified (Typst 0.15.1). Copy the imports you use.
#import "@preview/chronos:0.3.0"
#import "@preview/pintorita:0.1.4"
#import "@preview/mastermind:0.3.0" as mm
#import "@preview/timeliney:0.4.0"
#import "@preview/tdtr:0.6.1": tidy-tree-graph
#import "@preview/arborly:0.3.3": tree as arbtree
#import "@preview/twig:0.1.0": list-to-tree, tree-to-cetz
#import "@preview/cetz:0.4.2" as cetz4 // twig needs cetz 0.4.x; 0.5.x breaks it
#import "@preview/treet:1.0.0": tree-list
#import "@preview/curryst:0.6.0": rule, prooftree
#import "@preview/fitchcraft:1.0.1" as fitch
#import "@preview/lovelace:0.3.1": pseudocode-list
#import "@preview/algorithmic:1.0.7" as algorithmic
#import "@preview/codly:2.0.0" as codly
#import "@preview/pinit:0.2.2": pin, pinit-highlight, pinit-point-from
#import "@preview/wrap-it:0.1.1": wrap-content
#import "@preview/subpar:0.2.2"
#import "@preview/chalks:0.1.1" as chalks
#import "@preview/scrawl:0.1.0": scrawl-box, scrawl-ellipse, scrawl-underline
#import "@preview/sourcecraft:0.1.0": source-diagram
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@preview/cetz:0.5.3"
#import "@preview/cetz-plot:0.1.4": plot
#import "@preview/lilaq:0.6.0" as lq
#import "@preview/marginalia:0.3.1" as marginalia
#import "@preview/drafting:0.2.2": margin-note, set-page-properties

#let c-blue = rgb("#2f5d8a")
#let c-teal = rgb("#3b7a78")
#let c-green = rgb("#3f7d4e")
#let c-red = rgb("#b04a3f")
#let c-soft = rgb("#f6f7f9")
#let c-muted = rgb("#5c5c6e")

// Sequence diagram. Gotcha: call `import chronos: *` INSIDE diagram({..}); participants need _par first.
#let demo-sequence() = chronos.diagram({
  import chronos: *
  _par("C", display-name: "Client")
  _par("S", display-name: "API server")
  _par("D", display-name: "Database")
  _seq("C", "S", comment: "POST /order", enable-dst: true)
  _seq("S", "D", comment: "INSERT", enable-dst: true)
  _seq("D", "S", comment: "ok", disable-src: true, dashed: true)
  _seq("S", "C", comment: "201 Created", disable-src: true, dashed: true)
})

// ER diagram from Pintora markup via a raw string. Gotcha: pintorita runs a WASM renderer; dark theme default, ok on white.
#let demo-er-pintora() = pintorita.render("erDiagram
  CUSTOMER {
    int id PK
    string name
  }
  ORDER {
    int id PK
    int customer_id FK
  }
  CUSTOMER ||--o{ ORDER : places
")

// UML class diagram from manual spec (mastermind). Gotcha: positions are cetz coordinates; mm.class not `class` to avoid name clash.
#let demo-uml-class() = {
  let classes = (
    mm.class("Shape", center: (0, 0), type: "abstract", attributes: ("# name: String",), methods: ("+ area(): double",)),
    mm.class("Circle", center: (-4, -5), attributes: ("- r: double",), methods: ("+ area(): double",)),
    mm.class("Rect", center: (4, -5), attributes: ("- w, h: double",), methods: ("+ area(): double",)),
  )
  let rels = (
    mm.inheritance("Shape", "Circle", from-side: "south", to-side: "north"),
    mm.inheritance("Shape", "Rect", from-side: "south", to-side: "north"),
  )
  mm.draw-uml-diagram(classes, rels)
}

// SDLC Gantt (timeliney; chosen over gantty: coloured bars, no date-dict boilerplate). Gotcha: numeric columns, group headers must match column count; import timeliney: * INSIDE the timeline body.
#let demo-gantt-timeliney() = timeliney.timeline(show-grid: true, {
  import timeliney: *
  headerline(group(([*Q1*], 3)), group(([*Q2*], 3)))
  headerline(group(..("Jan", "Feb", "Mar", "Apr", "May", "Jun").map(strong)))
  taskgroup(title: [*Plan*], {
    task("Requirements", (0, 1), style: (stroke: 8pt + rgb("#2f5d8a")))
    task("Design", (1, 2), style: (stroke: 8pt + rgb("#3b7a78")))
  })
  taskgroup(title: [*Build*], {
    task("Implementation", (2, 4), style: (stroke: 8pt + rgb("#3f7d4e")))
    task("Testing", (4, 5), style: (stroke: 8pt + rgb("#b04a3f")))
  })
  milestone(at: 5.5, style: (stroke: (dash: "dashed")), align(center)[*Release*])
})

// Tidy tree from bullet list (tdtr). Gotcha: exactly ONE root bullet; nodes accept math/raw.
#let demo-tree-tdtr() = scale(150%, reflow: true, tidy-tree-graph(compact: true)[
  - $f(4)$
    - $f(3)$
      - $f(2)$
        - $f(1)$
        - $f(0)$
      - $f(1)$
    - $f(2)$
      - $f(1)$
      - $f(0)$
])

// Binary tree with explicit children (arborly). Gotcha: syntax is nested [label [child] [child]] brackets; leaf needs its own [].
#let demo-tree-arborly() = arbtree[8
  [3 [1] [6 [4] [7]]]
  [10 [#h(0pt)] [14 [13]]]
]

// Suffix/trie tree on CeTZ (twig). Gotcha: twig is incompatible with cetz 0.5.x ("no key tags"), use its own cetz 0.4.x import; tree-to-cetz must sit inside that canvas; list-to-tree takes a bullet list, `/ term: child` nodes carry edge labels.
#let demo-tree-twig() = cetz4.canvas({
  import cetz4.draw: *
  tree-to-cetz(
    list-to-tree([
      - #[]
        / a: #[]
          / t: cat
          / n: and
        / b: #[]
          / e: be
    ]),
    grow: 1.6, spread: 2,
  )
})

// Directory/outline tree (treet). Gotcha: text-only, ASCII-art markers; for file layouts not algorithm trees.
#let demo-tree-list() = tree-list[
  - src
    - main.rs
    - lib
      - parser.rs
  - Cargo.toml
]

// Inference-rule proof tree (curryst). Gotcha: rule(label:, name:, premises..., conclusion) last arg is the conclusion; nest rules as premises.
#let demo-proof-tree() = prooftree(rule(
  name: $arrow.r "E"$,
  rule(name: $"Ax"$, $Gamma tack A arrow.r B$),
  rule(name: $"Ax"$, $Gamma tack A$),
  $Gamma tack B$,
))

// Fitch-style natural deduction (fitchcraft). Gotcha: array of rows; `open`/`close` bracket sub-proofs, `assume` marks hypothesis.
#let demo-fitch() = fitch.proof((
  fitch.open,
  $p and q$,
  fitch.assume,
  ($p$, $and "E" quad 1$),
  ($q$, $and "E" quad 1$),
  ($q and p$, $and "I" quad 3,2$),
  fitch.close,
  ($(p and q) arrow.r (q and p)$, $arrow.r "I" quad 1-4$),
))

// Pseudocode (lovelace; chosen over algorithmic for plain nested-list syntax and free-form keywords). Gotcha: one list item per line, nesting = indent; no comment() helper in 0.3.1: use #h(1fr) for right-aligned comments.
#let demo-pseudocode() = {
  pseudocode-list(title: [Binary search (sorted $A$, target $v$)])[
    + $l <- 1$, $r <- n$ #h(1fr) #text(fill: c-muted)[▷ search window]
    + *while* $l <= r$ *do*
      + $m <- floor((l + r) / 2)$
      + *if* $A[m] = v$ *then return* $m$
      + *else if* $A[m] < v$ *then* $l <- m + 1$
      + *else* $r <- m - 1$
    + *end*
    + *return* $-1$ #h(1fr) #text(fill: c-muted)[▷ not found]
  ]
}

// Pseudocode (algorithmic, alternative with built-in keyword functions). Gotcha: needs `show: style-algorithm` at document level for full styling; blocks are { import algorithmic: * ... } code blocks.
#let demo-pseudocode-algorithmic() = {
  import algorithmic: algorithm-figure, style-algorithm
  show: style-algorithm
  algorithm-figure("Euclid", {
    import algorithmic: *
    Procedure("GCD", ("a", "b"), {
      While($b != 0$, {
        Assign[$t$][$b$]
        Assign[$b$][$a mod b$]
        Assign[$a$][$t$]
      })
      Return[$a$]
    })
  })
}

// Code block with filename badge and highlighted lines (codly 2.x). Gotcha: highlights is an array of dicts (line is 1-based); needs no global init since codly.new is explicit.
#let demo-code() = codly.new(
  ```py
  def fib(n):
      a, b = 0, 1
      for _ in range(n):
          a, b = b, a + b
      return a
  ```,
  file: "fib.py",
  highlights: ((line: 4, fill: c-green.lighten(75%)),),
)

// Annotate parts of an equation with arrows (pinit). Gotcha: pins are inline markers, the annotation functions reference them by id AFTER the text; needs pinit-point-from placement offsets.
#let demo-pinit() = [
  #set text(size: 12pt)
  $ #pin(1)"loss"#pin(2) = 1 / n sum_(i=1)^n (y_i - #pin(3)hat(y)_i#pin(4))^2 $
  #pinit-highlight(1, 2, fill: c-blue.transparentize(80%))
  #pinit-highlight(3, 4, fill: c-red.transparentize(80%))
  #v(1.4em)
  #pinit-point-from(2, offset-dx: 0pt, offset-dy: 8pt)[#text(size: 9pt, fill: c-blue)[mean squared error]]
  #pinit-point-from(4, offset-dx: 0pt, offset-dy: 8pt)[#text(size: 9pt, fill: c-red)[model prediction]]
]

// Text wrapped around a figure (wrap-it). Gotcha: wrap-content(figure, body, align:) can't be center; body must be plain paragraphs.
#let demo-wrap() = wrap-content(
  rect(width: 3.2cm, height: 2.4cm, fill: c-soft, stroke: c-blue)[#align(center + horizon)[figure]],
  align: right + top,
)[
  #lorem(55)
]

// Side-by-side sub-figures with (a)/(b) labels (subpar). Gotcha: each sub-figure followed by its label; main caption goes on the grid.
#let demo-subfigures() = subpar.grid(
  figure(rect(width: 100%, height: 2cm, fill: c-soft, stroke: c-blue), caption: [Before]), <sub-a>,
  figure(rect(width: 100%, height: 2cm, fill: c-soft, stroke: c-green), caption: [After]), <sub-b>,
  columns: (1fr, 1fr),
  caption: [Two panels sharing a number.],
  label: <sub-fig>,
)

// Hand-drawn sketch (chalks). Gotcha: import as module, it exports line/rect/ellipse that shadow built-ins.
#let demo-sketch-chalks() = chalks.sketch(220pt, 90pt,
  chalks.rect((5, 20), (65, 70), fill: "hachure"),
  chalks.circle((150, 45), 28, fill: "shade"),
  chalks.arrow((70, 45), (118, 45)),
)

// Hand-drawn frames/underline (scrawl). Gotcha: pure Typst, no WASM; box/ellipse are block-level, wrap in #box(..) to keep them inline.
#let demo-sketch-scrawl() = [
  #box(scrawl-box(fill: rgb("#fffbe6"))[Key idea]) and some #scrawl-underline[underlined] text, #box(scrawl-ellipse(paint: c-red)[circled]).
]

// UML class diagram straight from Java source (sourcecraft). Gotcha: default theme uses font "Consolas" => unknown-font warning, so pass a FULL theme dict (copied from the package, member-font changed); partial themes crash. Also infers relations from code; grammar: "java" or "csharp".
#let demo-uml-source() = source-diagram(
  "interface Shape {
  double area();
}
class Circle implements Shape {
  private double r;
  public double area() {}
}
class Square implements Shape {
  private double s;
  public double area() {}
}",
  grammar: "java",
  theme: (
    // Header colors per class type
    class-header: (
      class:      (fill: rgb("#D4E6F1"), stroke: rgb("#2980B9")),
      abstract:   (fill: rgb("#E8DAEF"), stroke: rgb("#8E44AD")),
      interface:  (fill: rgb("#D5F5E3"), stroke: rgb("#27AE60")),
      enum:       (fill: rgb("#FCF3CF"), stroke: rgb("#F39C12")),
      annotation: (fill: rgb("#FADBD8"), stroke: rgb("#E74C3C")),
    ),
    // Body area
    class-body: (
      fill: white,
      stroke: rgb("#888888"),
    ),
    // Typography
    font: (
      class-name-size: 11pt,
      member-size: 9pt,
      member-font: "DejaVu Sans Mono",
      stereotype-size: 8pt,
    ),
    // Visibility icon colors
    visibility-colors: (
      public:    rgb("#27AE60"),
      private:   rgb("#E74C3C"),
      protected: rgb("#F39C12"),
      package:   rgb("#2980B9"),
    ),
    // Visibility display symbols (shown in the diagram)
    visibility-symbols: (
      public:    (field: "○", method: "●"),
      private:   (field: "□", method: "■"),
      protected: (field: "◇", method: "◆"),
      package:   (field: "△", method: "▲"),
    ),
    // Relation styles
    relation: (
      stroke-thickness: 1pt,
      color: rgb("#2C3E50"),
      label-size: 8pt,
      card-size: 8pt,
    ),
    // Box styling
    corner-radius: 3pt,
    padding: 6pt,
    min-width: 100pt,
  ),
)

// ---- hand-built diagrams (fletcher / cetz / lilaq) ----

// Waterfall (staircase) vs agile (loop). Gotcha: fletcher nodes by (col, row) coords; the loop uses a bent edge from last to first node.
#let demo-sdlc-models() = {
  let st(c) = (fill: c.lighten(80%), stroke: c, corner-radius: 3pt, inset: 5pt)
  stack(dir: ltr, spacing: 8mm,
    diagram(
      node-stroke: 0.6pt, spacing: (6mm, 7mm),
      node((0, 0), [Requirements], ..st(c-blue)),
      node((1, 1), [Design], ..st(c-teal)),
      node((2, 2), [Implement], ..st(c-green)),
      node((3, 3), [Test], ..st(c-red)),
      edge((0, 0), (1, 0), (1, 1), "-|>"),
      edge((1, 1), (2, 1), (2, 2), "-|>"),
      edge((2, 2), (3, 2), (3, 3), "-|>"),
      node((1.5, -0.6), text(weight: "bold", fill: c-muted)[Waterfall], stroke: none, fill: none),
    ),
    diagram(
      node-stroke: 0.6pt, spacing: (8mm, 10mm),
      node((0, 0), [Plan], ..st(c-blue)),
      node((1, 0), [Build], ..st(c-teal)),
      node((1, 1), [Test], ..st(c-green)),
      node((0, 1), [Review], ..st(c-red)),
      edge((0, 0), (1, 0), "-|>"),
      edge((1, 0), (1, 1), "-|>"),
      edge((1, 1), (0, 1), "-|>"),
      edge((0, 1), (0, 0), "-|>"),
      node((0.5, 0.5), text(fill: c-muted, size: 9pt)[sprint], stroke: none, fill: none),
      node((0.5, -0.6), text(weight: "bold", fill: c-muted)[Agile], stroke: none, fill: none),
    ),
  )
}

// Git branching graph. Gotcha: commits are small circles placed on a (x = time, y = branch) grid; merge = second incoming edge.
#let demo-git-graph() = {
  let cm(pos, name, col) = node(pos, [], name: label(name), shape: circle, radius: 5pt, fill: col, stroke: none)
  diagram(
    spacing: (16mm, 9mm),
    cm((0, 0), "m1", c-blue), cm((1, 0), "m2", c-blue), cm((3, 0), "m3", c-blue), cm((4, 0), "m4", c-blue),
    cm((1.7, 1), "f1", c-green), cm((2.4, 1), "f2", c-green),
    edge(label("m1"), label("m2"), "-", stroke: c-blue),
    edge(label("m2"), label("m3"), "-", stroke: c-blue),
    edge(label("m3"), label("m4"), "-", stroke: c-blue),
    edge(label("m2"), label("f1"), "-", stroke: c-green, bend: 0deg),
    edge(label("f1"), label("f2"), "-", stroke: c-green),
    edge(label("f2"), label("m3"), "-", stroke: c-green),
    node((4.6, 0), text(fill: c-blue, size: 9pt)[`main`], stroke: none),
    node((2.05, 1.5), text(fill: c-green, size: 9pt)[`feature`], stroke: none),
  )
}

// Memory pictures: array with indices, singly linked list, hash table with chaining. Gotcha: pure cetz rects so box widths line up with index labels.
#let demo-memory() = {
  import cetz.draw: *
  cetz.canvas({
    // array
    for (i, v) in (7, 3, 9, 1, 5).enumerate() {
      rect((i, 0), (i + 1, 0.8), fill: c-soft, stroke: c-blue)
      content((i + 0.5, 0.4), str(v))
      content((i + 0.5, -0.3), text(size: 8pt, fill: c-muted)[#i])
    }
    content((-0.2, 0.4), anchor: "east", text(size: 9pt, fill: c-blue)[`A`])
    // linked list
    for (i, v) in (4, 8, 2).enumerate() {
      let x = 8 + i * 2.4
      rect((x, 0), (x + 1, 0.8), fill: c-soft, stroke: c-teal)
      rect((x + 1, 0), (x + 1.7, 0.8), fill: c-teal.lighten(70%), stroke: c-teal)
      content((x + 0.5, 0.4), str(v))
      if i < 2 { line((x + 1.35, 0.4), (x + 2.4, 0.4), mark: (end: ">"), stroke: c-teal) }
      else { content((x + 1.35, 0.4), text(size: 8pt)[∅]) }
    }
    content((7.6, 0.4), anchor: "east", text(size: 9pt, fill: c-teal)[`head`])
    // hash table
    for i in range(4) {
      rect((0, -2 - i * 0.8), (1, -1.2 - i * 0.8), fill: c-soft, stroke: c-red)
      content((-0.3, -1.6 - i * 0.8), text(size: 8pt, fill: c-muted)[#i])
    }
    for (row, keys) in ((0, ("k1", "k5")), (2, ("k2",))) {
      let y = -1.6 - row * 0.8
      let prev = (1, y)
      for (j, k) in keys.enumerate() {
        let x = 2 + j * 2
        line(prev, (x, y), mark: (end: ">"), stroke: c-red)
        rect((x, y - 0.35), (x + 1.2, y + 0.35), fill: c-red.lighten(85%), stroke: c-red)
        content((x + 0.6, y), text(size: 9pt)[#k])
        prev = (x + 1.2, y)
      }
    }
  })
}

// BFS traversal with visit order as fill/labels. Gotcha: fletcher node fills are set per node; edges use "-" for undirected.
#let demo-graph-bfs() = {
  let order = (A: 1, B: 2, C: 3, D: 4, E: 5, F: 6)
  let pos = (A: (1, 0), B: (0, 1), C: (2, 1), D: (-0.5, 2), E: (1, 2), F: (2.5, 2))
  diagram(
    spacing: (14mm, 12mm),
    ..pos.pairs().map(((k, p)) => node(p, [#k], name: label(k), shape: circle, fill: c-blue.lighten((80 - order.at(k) * 11) * 1%), stroke: c-blue)),
    ..(("A", "B"), ("A", "C"), ("B", "D"), ("B", "E"), ("C", "E"), ("C", "F")).map(((a, b)) => edge(label(a), label(b), "-", stroke: c-muted)),
    ..pos.pairs().map(((k, p)) => node((p.at(0) + 0.28, p.at(1) - 0.34), text(size: 8pt, fill: c-red)[#order.at(k)], stroke: none)),
  )
}

// Recursion call stack for fact(3). Gotcha: frames drawn bottom-up with cetz rects; return values annotated on the right.
#let demo-call-stack() = {
  import cetz.draw: *
  cetz.canvas({
    let frames = (("fact(3)", "n=3", "6"), ("fact(2)", "n=2", "2"), ("fact(1)", "n=1", "1"))
    for (i, (f, v, r)) in frames.enumerate() {
      let y = i * 1.1
      rect((0, y), (4.2, y + 0.9), fill: (c-blue, c-teal, c-green).at(i).lighten(82%), stroke: (c-blue, c-teal, c-green).at(i))
      content((1.2, y + 0.45), raw(f))
      content((3.1, y + 0.45), text(size: 9pt, fill: c-muted, raw(v)))
      content((4.6, y + 0.45), anchor: "west", text(size: 9pt, fill: c-red)[returns #r])
    }
    content((2.1, 3.5), text(size: 9pt, fill: c-muted)[top of stack ↑])
  })
}

// Big-O growth curves (lilaq). Gotcha: lilaq draws a whole diagram; use lq.plot(xs, ys, label:) per curve and ylim to clip the exponential.
#let demo-bigo-plot() = {
  let xs = lq.linspace(1, 10, num: 60)
  lq.diagram(
    width: 8cm, height: 5cm, legend: (position: left + top),
    ylim: (0, 60), xlabel: [$n$], ylabel: [steps],
    lq.plot(xs, xs.map(x => 1 + 0 * x), label: [$O(1)$], color: c-muted, mark: none),
    lq.plot(xs, xs.map(x => calc.ln(x) * 3), label: [$O(log n)$], color: c-green, mark: none),
    lq.plot(xs, xs, label: [$O(n)$], color: c-blue, mark: none),
    lq.plot(xs, xs.map(x => x * calc.ln(x)), label: [$O(n log n)$], color: c-teal, mark: none),
    lq.plot(xs, xs.map(x => x * x / 2), label: [$O(n^2)$], color: c-red, mark: none),
  )
}

// Margin notes (marginalia). Gotcha: page-level: apply `#show: setup-marginalia` ONCE at document top (it owns page margins); book: false keeps pages un-mirrored. Text column narrows by the note width (here 38mm right gutter), so use only when notes are wanted.
#let setup-marginalia = marginalia.setup.with(
  book: false,
  inner: (far: 12mm, width: 0mm, sep: 0mm),
  outer: (far: 8mm, width: 38mm, sep: 6mm),
  top: 2.4cm, bottom: 2.4cm,
)
// Gotcha 2: default note marker uses font "Inter" (unknown-font warning if absent): pass a numbering with your own style, as `note` below.
#let note = marginalia.note.with(numbering: marginalia.note-numbering.with(style: text.with(weight: "bold", size: 6pt, fill: c-blue)))
#let demo-marginnote-marginalia() = [
  Binary search halves the window each step.#note[Needs a *sorted* array; $O(log n)$.] The loop invariant is that $v$, if present, lies in $[l, r]$.#note[Source: Lecture 4, slide 12.]
]

// Margin notes (drafting). Gotcha: call `set-page-properties()` once after any `set page`; notes are drawn into the page margin so keep a right margin >= 4cm or they clip. Alternative to marginalia; marginalia positions/avoids collisions better.
#let demo-marginnote-drafting() = [
  Binary search halves the window each step.#margin-note[Needs a *sorted* array; $O(log n)$.] The invariant keeps $v$ inside $[l, r]$.#margin-note(stroke: c-green)[Source: Lecture 4.]
]
