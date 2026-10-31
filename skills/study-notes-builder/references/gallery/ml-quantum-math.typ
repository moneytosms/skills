// ml-quantum-math.typ: compile-verified snippets (Typst 0.15.1) for quantum, math/plots, AI/ML/DL.
// Each demo-* is self-contained and meant to be copied. Bump versions with scripts/sync-versions.sh.
// Palette matches template.typ.

#import "@preview/quill:0.8.0": quantum-circuit, lstick, rstick, ctrl, targ, meter, gate
#import "@preview/czbloch:0.1.0"
#import "@preview/tybloch:0.1.0": bloch-from-spherical, bloch-state-rotation-evolution
#import "@preview/lilaq:0.6.0" as lq
#import "@preview/cetz:0.5.3"
#import "@preview/cetz-plot:0.1.4": plot
#import "@preview/cetz-venn:0.2.0"
#import "@preview/mannot:0.4.0": markhl, annot, markul
#import "@preview/equate:0.3.3": equate
#import "@preview/neural-netz:0.3.0": draw-network
#import "@preview/neural-viz:0.1.0" as nviz
#import "@preview/confy:0.1.0": confy
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@preview/diagraph:0.3.8"
#import "@preview/probabilitree:0.1.3": proba-tree

#let g-blue = rgb("#2f5d8a")
#let g-teal = rgb("#3b7a78")
#let g-green = rgb("#3f7d4e")
#let g-red = rgb("#b04a3f")
#let g-soft = rgb("#f6f7f9")

// Bell-state prep + measurement. Cells are gates; integer = empty wire cells; `[\ ]` starts the next wire.
#let demo-quill-bell() = quantum-circuit(
  lstick($|0〉$), $H$, ctrl(1), meter(), [\ ],
  lstick($|0〉$), 1, targ(), meter(),
)

// Teleportation-style circuit: classically controlled gates via ctrl(..., wire-count) and `meter(target: ..)`.
#let demo-quill-teleport() = quantum-circuit(
  lstick($|psi〉$), 1, ctrl(1), $H$, meter(target: 2), [\ ],
  lstick($|0〉$), $H$, targ(), 1, 1, ctrl(1, wire-count: 2), [\ ],
  lstick($|0〉$), 1, 1, 1, 1, $X$, rstick($|psi〉$),
)

// czbloch: preset states via ..czbloch.plus; custom theta/phi in degrees. Simpler API, labels built in.
#let demo-czbloch() = stack(
  dir: ltr, spacing: 12pt,
  czbloch.bloch(..czbloch.zero, length: 2.6cm),
  czbloch.bloch(..czbloch.plus, length: 2.6cm, state-color: g-green),
  czbloch.bloch(theta: 60deg, phi: 45deg, length: 2.6cm, state-color: g-red),
)

// tybloch: bloch-from-spherical(theta, phi) plus projections; rotation-evolution shows a path (more expressive, slower).
#let demo-tybloch() = stack(
  dir: ltr, spacing: 12pt,
  bloch-from-spherical(45deg, 45deg, state-color: g-blue, show-projections: true),
  bloch-state-rotation-evolution((1, 25deg, 90deg), (0deg, 0deg), 360deg, number-of-shadows: 11),
)

// lilaq line + scatter + errorbars. lq.diagram takes plot objects; xlabel/ylabel are named args of diagram.
#let demo-lilaq-line() = {
  let xs = lq.linspace(0, 2 * calc.pi, num: 60)
  lq.diagram(
    width: 9cm, height: 5cm, xlabel: $x$, ylabel: $y$,
    lq.plot(xs, xs.map(calc.sin), color: g-blue, mark: none, label: $sin x$),
    lq.plot(xs, xs.map(calc.cos), color: g-red, mark: none, label: $cos x$),
    lq.scatter((1, 2, 3, 4), (0.5, -0.3, 0.8, 0.1), color: g-green, size: 5pt),
  )
}

// lilaq bar chart with error bars (yerr) on a plot; ticks at integer positions.
#let demo-lilaq-bar() = {
  let xs = (1, 2, 3, 4)
  lq.diagram(
    width: 8cm, height: 5cm, ylabel: [accuracy],
    lq.bar(xs, (0.62, 0.74, 0.81, 0.88), fill: g-teal),
    lq.plot(xs, (0.62, 0.74, 0.81, 0.88), yerr: (0.04, 0.03, 0.05, 0.02), stroke: none, mark: "o", color: black),
  )
}

// lilaq heatmap via colormesh over a grid; z is a 2D array indexed [y][x].
#let demo-lilaq-heatmap() = {
  let xs = lq.linspace(-2, 2, num: 40)
  let ys = lq.linspace(-2, 2, num: 40)
  lq.diagram(
    width: 6cm, height: 6cm, xlabel: $x$, ylabel: $y$,
    lq.colormesh(xs, ys, (x, y) => calc.exp(-(x * x + y * y)), map: color.map.viridis),
  )
}

// lilaq contour of a 2D function with labelled-free lines.
#let demo-lilaq-contour() = {
  let xs = lq.linspace(-3, 3, num: 60)
  let ys = lq.linspace(-3, 3, num: 60)
  lq.diagram(
    width: 6cm, height: 6cm, xlabel: $x$, ylabel: $y$,
    lq.contour(xs, ys, (x, y) => x * x + y * y / 2, levels: 6, map: color.map.mako),
  )
}

// cetz-plot: function plot with the area under the curve shaded (fill: true + domain-limited add-fill-between).
#let demo-cetz-plot-area() = cetz.canvas({
  plot.plot(
    size: (7, 4), x-label: $x$, y-label: $f(x)$, axis-style: "school-book", x-tick-step: 1, y-tick-step: 1,
    {
      plot.add(domain: (0, 4), x => calc.pow(x, 2) / 4, style: (stroke: 1.2pt + g-blue))
      plot.add(domain: (1, 3), x => calc.pow(x, 2) / 4, fill: true, style: (stroke: none, fill: g-blue.transparentize(70%)))
    },
  )
})

// cetz-venn: draws inside a cetz canvas; style args (fill/stroke) are named args of venn2/venn3. Pass cetz.draw content for labels.
#let demo-cetz-venn() = cetz.canvas({
  import cetz.draw: content
  cetz-venn.venn2(a-fill: g-blue.transparentize(65%), b-fill: g-red.transparentize(65%))
  content((-1.2, 0), $A$)
  content((1.2, 0), $B$)
  content((0, 0), $A inter B$)
})

// mannot: markhl marks a sub-expression, annot (placed in the same $...$) labels it by tag. Needs enough page margin around the equation.
#let demo-mannot() = block(inset: (x: 2cm, y: 1cm), $
  markhl(sum_(i=1)^n (y_i - hat(y)_i)^2, tag: #<sse>, color: #g-blue) / n
  #annot(<sse>, pos: top)[squared error]
$)

// equate: `#show: equate.with(sub-numbering: true)` makes multi-line aligned blocks one equation; breakable across pages.
#let demo-equate() = {
  show: equate.with(breakable: true, sub-numbering: false)
  set math.equation(numbering: none)
  $
    L(w) &= 1/2 (y - w^top x)^2 \
    nabla_w L &= -(y - w^top x) x \
    w &<- w - eta nabla_w L
  $
}

// neural-netz: draw-network takes layer dictionaries (type: input/conv/pool/convres/...); arrows between layers are automatic.
#let demo-neural-netz-cnn() = draw-network(
  (
    (type: "input", image: none, label: "Input"),
    (type: "conv", widths: (1, 1), channels: ("", "16"), offset: 2, label: "Conv"),
    (type: "pool"),
    (type: "conv", widths: (1, 1), channels: ("", "32"), offset: 2, label: "Conv"),
    (type: "pool"),
  ),
  palette: "cold", scale: 90%,
)

// neural-viz: block-diagram style (dataset -> encoder -> head); nodes must be draw-node'd, arrows via draw-arrows. Best for pipelines, not layer-wise MLPs.
#let demo-neural-viz() = nviz.graph-canvas({
  let ds = nviz.make-dataset("Data", pos: (1.0, 0.0))
  let enc = nviz.make-trapezoid("Encoder", subtitle: "Conv stack", after: ds, gap: 1.2)
  let head = nviz.make-box("Head", subtitle: "Softmax", after: enc, gap: 1.2)
  nviz.draw-node(ds)
  nviz.draw-node(enc)
  nviz.draw-node(head)
  nviz.draw-arrows((
    nviz.make-arrow(ds, enc, label: [input]),
    nviz.make-arrow(enc, head, label: [features]),
  ))
})

// confy: n x n matrix + labels; cmap takes a color.map array. Use `title-row`/`title-col` for axis titles.
#let demo-confy() = confy(
  ("cat", "dog", "bird"),
  ((42, 5, 3), (4, 38, 8), (1, 6, 43)),
  title-row: "Predicted", title-col: "Actual", cmap: color.map.mako,
)

// fletcher: MLP as a layered node graph, programmatic nodes/edges. Name nodes with labels via `name: label(..)`.
#let demo-fletcher-mlp() = {
  let layers = (3, 4, 2)
  diagram(
    node-stroke: 0.6pt + g-blue, node-fill: g-soft, spacing: (22mm, 6mm),
    for (l, n) in layers.enumerate() {
      for i in range(n) {
        node((l, i - n / 2), $#(if l == 0 { "x" } else if l == 2 { "y" } else { "h" })_#(i + 1)$,
          shape: circle, name: label("n" + str(l) + "-" + str(i)))
      }
    },
    for l in range(layers.len() - 1) {
      for i in range(layers.at(l)) {
        for j in range(layers.at(l + 1)) {
          edge(label("n" + str(l) + "-" + str(i)), label("n" + str(l + 1) + "-" + str(j)), "->", stroke: 0.3pt + g-teal)
        }
      }
    },
  )
}

// fletcher: transformer-block flow (attention + FFN with residuals). Uses node coords on a vertical axis; bent dashed edges as residual skips (no labels, they get clipped).
#let demo-fletcher-transformer() = diagram(
  node-stroke: 0.7pt + g-blue, node-inset: 6pt, spacing: (14mm, 9mm),
  node((0, 4), [Input $x$], stroke: none),
  node((0, 3), [Multi-head attention], fill: g-blue.lighten(75%), name: <att>),
  node((0, 2), [Add & LayerNorm], fill: g-soft, name: <n1>),
  node((0, 1), [Feed-forward], fill: g-teal.lighten(75%), name: <ffn>),
  node((0, 0), [Add & LayerNorm], fill: g-soft, name: <n2>),
  edge((0, 4), <att>, "->"), edge(<att>, <n1>, "->"), edge(<n1>, <ffn>, "->"), edge(<ffn>, <n2>, "->"),
  edge((0, 4), <n1>, "->", bend: -60deg, stroke: (paint: g-red, dash: "dashed")),
  edge(<n1>, <n2>, "->", bend: -60deg, stroke: (paint: g-red, dash: "dashed")),
)

// fletcher: backprop on a computation graph; forward edges solid, gradient edges dashed red, labels are math.
#let demo-fletcher-backprop() = diagram(
  node-stroke: 0.7pt + g-blue, node-fill: g-soft, spacing: (22mm, 12mm),
  node((0, 0), $w$, name: <w>), node((0, 1), $x$, name: <x>),
  node((1, 0.5), $z = w x$, name: <z>), node((2, 0.5), $L = (z - y)^2$, name: <l>),
  edge(<w>, <z>, "->"), edge(<x>, <z>, "->"), edge(<z>, <l>, "->"),
  edge(<l>, <z>, "-->", bend: 25deg, stroke: g-red, label: $2(z-y)$, label-side: left),
  edge(<z>, <w>, "-->", bend: 25deg, stroke: g-red, label: $x$, label-side: left),
)

// diagraph: Graphviz DOT rendered in WASM; node labels are evaluated as Typst math (write h_1, hat(y); NO dollar signs; only simple forms, hat(y) stays literal so use unicode ŷ). Great for DAGs/automata.
#let demo-diagraph() = diagraph.render(
  "digraph { rankdir=LR; node [shape=circle]; a [label=\"x\"]; b [label=\"h_1\"]; c [label=\"h_2\"]; d [label=\"ŷ\"]; a -> b; a -> c; b -> d; c -> d; }",
)

// probabilitree: left-to-right probability tree; data = (label, ..) with branch probabilities after each child label.
#let demo-probabilitree() = proba-tree(data: (
  $Omega$,
  ($D$, $0.01$, ($+$, $0.95$), ($-$, $0.05$)),
  ($overline(D)$, $0.99$, ($+$, $0.10$), ($-$, $0.90$)),
))
