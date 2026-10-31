// ============================================================================
//  diagrams.typ — reusable CeTZ / cetz-plot / fletcher builders
//  Uniform visual language for every figure in the notes.
//  Colour-first but dash + stroke-weight also vary, so greyscale still reads.
// ============================================================================

#import "@preview/cetz:0.5.3"
#import "@preview/cetz-plot:0.1.4": plot
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#import "template.typ": c-ink, c-accent, c-accent2, c-good, c-warn, c-bad, c-muted, c-rule, c-bg-soft

// fletcher needs node names as *labels* for edge lookup (strings are treated as
// mark/shorthand args). This helper builds a label from a dynamic string.
#let nm(s) = label(s)

// ---------------------------------------------------------------------------
//  layered-net — generic feed-forward architecture
//  layers : array of arrays of node labels, e.g. (($x_1$,$x_2$), ($z_1$,$z_2$), ($y$,))
//  fixed-last : style final layer's incoming edges as fixed (dashed) — MADALINE
//  bidir      : draw edges both directions — BAM
//  biases     : array of layer indices that emit a bias line to the next layer
// ---------------------------------------------------------------------------
#let layered-net(
  layers,
  fixed-last: false,
  bidir: false,
  biases: (),
  caption: none,
  x-sep: 26mm,
  y-sep: 12mm,
) = {
  let fig = diagram(
    node-stroke: 0.9pt + c-ink,
    node-fill: white,
    spacing: (x-sep, y-sep),
    {
      for (li, layer) in layers.enumerate() {
        let nrows = layer.len()
        for (ni, lbl) in layer.enumerate() {
          let y = ni - (nrows - 1) / 2
          node((li, y), lbl, name: nm("n-" + str(li) + "-" + str(ni)),
               shape: fletcher.shapes.circle, radius: 4.2mm)
        }
        if biases.contains(li) {
          let ytop = -(nrows - 1) / 2 - 1.15
          node((li, ytop), $1$, name: nm("b-" + str(li)),
               shape: fletcher.shapes.circle, radius: 3.4mm,
               stroke: 0.7pt + c-muted, fill: c-bg-soft)
        }
      }
      for li in range(layers.len() - 1) {
        let is-fixed = fixed-last and li == layers.len() - 2
        let strk = if is-fixed { (paint: c-muted, dash: "dashed", thickness: 0.8pt) }
                   else { (paint: c-accent, thickness: 0.9pt) }
        for ni in range(layers.at(li).len()) {
          for nj in range(layers.at(li + 1).len()) {
            let a = nm("n-" + str(li) + "-" + str(ni))
            let b = nm("n-" + str(li + 1) + "-" + str(nj))
            if bidir { edge(a, b, "<->", stroke: strk) }
            else { edge(a, b, "->", stroke: strk) }
          }
        }
        if biases.contains(li) {
          for nj in range(layers.at(li + 1).len()) {
            edge(nm("b-" + str(li)), nm("n-" + str(li + 1) + "-" + str(nj)), "->",
                 stroke: (paint: c-muted, thickness: 0.7pt, dash: "dotted"))
          }
        }
      }
    },
  )
  if caption != none { figure(fig, caption: caption) } else { fig }
}

// ---------------------------------------------------------------------------
//  neuron — single-unit close-up: inputs -> Σ -> activation -> output
// ---------------------------------------------------------------------------
#let neuron(
  inputs: ($x_1$, $x_2$, $x_3$),
  weights: ($w_1$, $w_2$, $w_3$),
  bias: $b$,
  act: $f(dot)$,
  out: $y$,
  caption: none,
) = {
  let n = inputs.len()
  let fig = diagram(spacing: (20mm, 9mm), {
    for (i, x) in inputs.enumerate() {
      let y = i - (n - 1) / 2
      node((0, y), x, name: nm("in-" + str(i)), stroke: none)
      edge(nm("in-" + str(i)), nm("sum"), "->", label: weights.at(i),
           label-size: 8pt, stroke: 0.8pt + c-accent)
    }
    node((1, -(n - 1) / 2 - 1), bias, name: nm("bias"), stroke: none)
    edge(nm("bias"), nm("sum"), "->", stroke: 0.7pt + c-muted)
    node((2, 0), $sum$, name: nm("sum"), shape: fletcher.shapes.circle, radius: 5mm,
         stroke: 0.9pt + c-ink)
    node((3.1, 0), act, name: nm("act"), stroke: 0.9pt + c-ink, inset: 6pt)
    edge(nm("sum"), nm("act"), "->", label: $y_"in"$, label-size: 8pt, stroke: 0.9pt + c-ink)
    node((4.3, 0), out, name: nm("out"), stroke: none)
    edge(nm("act"), nm("out"), "->", stroke: 0.9pt + c-ink)
  })
  if caption != none { figure(fig, caption: caption) } else { fig }
}

// ---------------------------------------------------------------------------
//  act-plot — activation f and its derivative f' on shared axes
// ---------------------------------------------------------------------------
#let act-plot(
  fn, dfn,
  domain: (-5, 5),
  title: none,
  y-domain: none,
  caption: none,
) = {
  let body = cetz.canvas(length: 1cm, {
    plot.plot(
      size: (7, 4.2),
      x-tick-step: 2, y-tick-step: 1,
      x-min: domain.at(0), x-max: domain.at(1),
      y-min: if y-domain != none { y-domain.at(0) } else { auto },
      y-max: if y-domain != none { y-domain.at(1) } else { auto },
      x-label: $x$, y-label: none,
      axis-style: "school-book",
      legend: "inner-north-west", legend-style: (item: (spacing: 0.15)),
      {
        plot.add(domain: domain, fn, samples: 120,
                 style: (stroke: 1.4pt + c-accent), label: $f(x)$)
        plot.add(domain: domain, dfn, samples: 120,
                 style: (stroke: (paint: c-bad, dash: "dashed", thickness: 1.1pt)),
                 label: $f'(x)$)
      },
    )
  })
  if caption != none { figure(body, caption: caption) } else { body }
}

// ---------------------------------------------------------------------------
//  decision-boundary — 2D ± scatter + separating line  w1 x1 + w2 x2 + b = 0
//  points : array of (x1, x2, cls)  with cls in (1, -1)
//  line   : (w1, w2, b)
// ---------------------------------------------------------------------------
#let decision-boundary(
  points,
  line: none,
  domain: (-2, 2),
  caption: none,
) = {
  let body = cetz.canvas(length: 1cm, {
    plot.plot(
      size: (5.4, 5.4),
      x-tick-step: 1, y-tick-step: 1,
      x-min: domain.at(0) - 0.4, x-max: domain.at(1) + 0.4,
      y-min: domain.at(0) - 0.4, y-max: domain.at(1) + 0.4,
      x-label: $x_1$, y-label: $x_2$,
      axis-style: "school-book",
      {
        let pos = points.filter(p => p.at(2) == 1).map(p => (p.at(0), p.at(1)))
        let neg = points.filter(p => p.at(2) != 1).map(p => (p.at(0), p.at(1)))
        if line != none {
          let (w1, w2, b) = line
          if w2 != 0 {
            plot.add(domain: (domain.at(0) - 0.4, domain.at(1) + 0.4),
                     x => (-b - w1 * x) / w2,
                     style: (stroke: 1.3pt + c-accent), label: [boundary])
          }
        }
        if pos.len() > 0 {
          plot.add(pos, mark: "o", mark-size: 0.26, style: (stroke: none),
                   mark-style: (stroke: 1pt + c-good, fill: c-good), label: $+1$)
        }
        if neg.len() > 0 {
          plot.add(neg, mark: "x", mark-size: 0.28, style: (stroke: none),
                   mark-style: (stroke: 1.4pt + c-bad), label: $-1$)
        }
      },
    )
  })
  if caption != none { figure(body, caption: caption) } else { body }
}

// ---------------------------------------------------------------------------
//  signal-flow-bpn — 2-2-1 net, forward (solid) vs error back-prop (dashed)
// ---------------------------------------------------------------------------
#let signal-flow-bpn(caption: none) = {
  let fig = diagram(
    node-stroke: 0.9pt + c-ink, node-fill: white, spacing: (30mm, 14mm),
    {
      node((0, 0.5), $x_1$, name: nm("x1"), shape: fletcher.shapes.circle, radius: 4mm)
      node((0, -0.5), $x_2$, name: nm("x2"), shape: fletcher.shapes.circle, radius: 4mm)
      node((1, 0.5), $z_1$, name: nm("z1"), shape: fletcher.shapes.circle, radius: 4mm)
      node((1, -0.5), $z_2$, name: nm("z2"), shape: fletcher.shapes.circle, radius: 4mm)
      node((2, 0), $y$, name: nm("y"), shape: fletcher.shapes.circle, radius: 4mm)
      for a in ("x1", "x2") {
        for b in ("z1", "z2") {
          edge(nm(a), nm(b), "->", stroke: (paint: c-accent, thickness: 1pt))
        }
      }
      edge(nm("z1"), nm("y"), "->", stroke: (paint: c-accent, thickness: 1pt))
      edge(nm("z2"), nm("y"), "->", stroke: (paint: c-accent, thickness: 1pt))
      edge(nm("y"), nm("z1"), "->", bend: 34deg,
           stroke: (paint: c-bad, dash: "dashed", thickness: 1pt),
           label: $delta_k$, label-size: 8pt)
      edge(nm("y"), nm("z2"), "->", bend: -34deg,
           stroke: (paint: c-bad, dash: "dashed", thickness: 1pt))
      node((0.5, 1.35), text(size: 8pt, fill: c-accent)[forward pass], stroke: none)
      node((1.7, 1.35), text(size: 8pt, fill: c-bad)[error back-propagation], stroke: none)
    },
  )
  if caption != none { figure(fig, caption: caption) } else { fig }
}

// ---------------------------------------------------------------------------
//  gaussian-kernel — RBF bell curve
// ---------------------------------------------------------------------------
#let gaussian-kernel(caption: none) = {
  let body = cetz.canvas(length: 1cm, {
    plot.plot(
      size: (7, 3.6), x-tick-step: 1, y-tick-step: 0.5,
      x-min: -3, x-max: 3, y-min: 0, y-max: 1.15,
      x-label: $r = norm(bold(x) - bold(c))$, y-label: $phi$,
      axis-style: "school-book",
      {
        plot.add(domain: (-3, 3), x => calc.exp(-x * x), samples: 120,
                 style: (stroke: 1.5pt + c-accent), label: $e^(-r^2)$)
      },
    )
  })
  if caption != none { figure(body, caption: caption) } else { body }
}

// ---------------------------------------------------------------------------
//  delay-line — TDNN tapped delay line feeding an MLP; variant: "fir" | "iir"
// ---------------------------------------------------------------------------
#let delay-line(taps: 3, variant: "fir", caption: none) = {
  let fig = diagram(node-stroke: 0.8pt + c-ink, node-fill: white, spacing: (17mm, 11mm), {
    node((0, 0), $x(t)$, name: nm("x"), stroke: none)
    for i in range(taps) {
      node((i + 1, 0), $z^(-1)$, name: nm("d" + str(i)),
           shape: fletcher.shapes.rect, inset: 5pt)
      if i == 0 { edge(nm("x"), nm("d0"), "->") }
      else { edge(nm("d" + str(i - 1)), nm("d" + str(i)), "->") }
    }
    node((1.5, -1.7), box(inset: 7pt)[MLP], name: nm("mlp"), stroke: 0.9pt + c-ink)
    edge(nm("x"), nm("mlp"), "->", stroke: 0.8pt + c-accent)
    for i in range(taps) { edge(nm("d" + str(i)), nm("mlp"), "->", stroke: 0.8pt + c-accent) }
    node((3, -1.7), $y(t)$, name: nm("y"), stroke: none)
    edge(nm("mlp"), nm("y"), "->")
    if variant == "iir" {
      edge(nm("y"), nm("mlp"), "->", bend: -42deg,
           stroke: (paint: c-bad, dash: "dashed", thickness: 0.9pt),
           label: text(size: 8pt)[feedback])
    }
  })
  if caption != none { figure(fig, caption: caption) } else { fig }
}

// ---------------------------------------------------------------------------
//  pattern-grid — pixel grid; +1 -> filled, else empty
// ---------------------------------------------------------------------------
#let pattern-grid(m, cell: 0.55, caption: none) = {
  let body = cetz.canvas(length: 1cm, {
    import cetz.draw: rect
    let rows = m.len()
    for r in range(rows) {
      let cols = m.at(r).len()
      for c in range(cols) {
        let v = m.at(r).at(c)
        let x = c * cell
        let y = (rows - 1 - r) * cell
        rect((x, y), (x + cell, y + cell),
             stroke: 0.7pt + c-ink,
             fill: if v == 1 { c-ink } else { white })
      }
    }
  })
  if caption != none { figure(body, caption: caption) } else { body }
}
