// ============================================================================
//  gallery/systems-hw.typ — compile-verified demos: low-level, hardware,
//  OS / parallel / networking, automata.  Typst 0.15.1, packages = latest
//  from the registry on 2026-11-01 (run scripts/sync-versions.sh to bump).
//  Usage: #import "gallery/systems-hw.typ": *   then   #demo-<name>()
//  Copy the body of a demo into your notes and edit; every demo is minimal.
// ============================================================================
#import "@preview/cetz:0.5.3"
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@preview/bytefield:0.0.8": bytefield, bitheader, bits, bytes, flag, note
#import "@preview/blockcell:0.1.0" as bc
#import "@preview/cntopo:0.1.0"
#import "@preview/circuiteria:0.2.1"
#import "@preview/zap:0.6.0"
#import "@preview/digidraw:0.9.4" as dd
#import "@preview/wavy:0.1.3"
#import "@preview/k-mapper:1.4.0": karnaugh
#import "@preview/truthfy:0.6.0": truth-table
#import "@preview/finite:0.5.1": automaton

// palette (matches references/template.typ)
#let _blue = rgb("#2f5d8a")
#let _teal = rgb("#3b7a78")
#let _green = rgb("#3f7d4e")
#let _red = rgb("#b04a3f")
#let _bg = rgb("#f6f7f9")
#let _ink = rgb("#22252b")
#let _lt(c) = c.lighten(78%)

// ---------------------------------------------------------------------------
//  PACKAGE DEMOS
// ---------------------------------------------------------------------------

// bytefield: protocol header / register layout. Gotcha: only ONE bitheader per
// bytefield; fields wrap at 32 bits by default; `flag` is a 1-bit field.
#let demo-bytefield() = bytefield(
  bitheader("bytes", 0, 15, 16, 31, text-size: 8pt),
  bits(16, fill: _lt(_blue))[Source port],
  bits(16, fill: _lt(_blue))[Destination port],
  bytes(4, fill: _lt(_teal))[Sequence number],
  bytes(4, fill: _lt(_teal))[Acknowledgment number],
  bits(4)[Offset], bits(6)[Rsvd],
  flag[URG], flag(fill: _lt(_green))[ACK], flag[PSH], flag[RST],
  flag(fill: _lt(_red))[SYN], flag(fill: _lt(_red))[FIN],
  bits(16)[Window],
  bits(16)[Checksum], bits(16)[Urgent pointer],
)

// blockcell: memory layouts as composable cells. Gotcha: `cell` sizes to text,
// pass width: for uniform fields; `schema`/`region`/`connector`/`target` stack
// vertically, use grid(...) to place several side by side.
#let demo-blockcell() = {
  let f(body, c) = bc.cell(fill: _lt(c), stroke: 0.8pt + c, width: 34pt)[#body]
  grid(
    columns: 2, column-gutter: 2.5em,
    bc.schema(title: raw("Vec<i32>"))[
      #bc.region[#f(`ptr`, _blue)#f(`len`, _teal)#f(`cap`, _teal)]
      #bc.connector()
      #bc.target(label: "(heap)", width: 150pt)[
        #f(`3`, _green)#f(`1`, _green)#f(`4`, _green)#bc.note[… len]
      ]
    ],
    bc.schema(title: raw("enum Msg"))[
      #bc.region[#bc.tag[`tag`]#bc.cell(fill: _lt(_blue), stroke: 0.8pt + _blue, width: 52pt)[`x: i32`]#bc.cell(fill: _bg, width: 34pt)[`pad`]]
    ],
  )
}

// cntopo: network icons on a cetz canvas. Gotcha: `icons(...)` returns a
// dict of drawing fns; re-exported `cntopo.cetz` is the matching cetz version
// (don't mix with your own cetz import for the same canvas).
#let demo-cntopo() = {
  let (router, switch, server, cloud) = cntopo.icons(
    fill: _lt(_blue), stroke: _blue + 1.5pt, fill-inner: _blue,
    stroke-inner: _blue, flat: false,
  )
  cntopo.cetz.canvas(length: 3.2em, {
    import cntopo.cetz.draw: *
    line((0, 0), (2.5, 0), stroke: _ink)
    line((2.5, 0), (5, 1), stroke: _ink)
    line((2.5, 0), (5, -1), stroke: _ink)
    line((-2.5, 0), (0, 0), stroke: (dash: "dashed", paint: _teal))
    cloud((-2.5, 0), label: [Internet])
    router((0, 0), label: [R1 · 10.0.0.1])
    switch((2.5, 0), label: [SW1])
    server((5, 1), label: [web])
    server((5, -1), label: [db])
  })
}

// circuiteria: block datapath (regfile -> mux -> ALU). Gotchas: ports are
// declared per side as (id:, name:); wire endpoints are "<elmt-id>-port-<id>";
// ALU ports are in1/in2/out; multiplexer ports are in0.. and out.
#let demo-datapath() = circuiteria.circuit({
  import circuiteria: *
  element.block(
    x: 0, y: 0, w: 3.2, h: 3.4, id: "rf", name: "Register file", name-anchor: "north", fill: _lt(_blue),
    ports: (
      west: ((id: "a1", name: "A1"), (id: "a2", name: "A2")),
      east: ((id: "d1", name: "RD1"), (id: "d2", name: "RD2")),
    ),
  )
  element.block(
    x: 0, y: -2.8, w: 3.2, h: 1.2, id: "imm", name: "Imm gen", fill: _lt(_teal),
    ports: (east: ((id: "o"),)),
  )
  element.multiplexer(
    x: 4.8, y: -1.3, w: 1, h: 2.4, id: "mux", entries: ("reg", "imm"),
    fill: _lt(_green),
  )
  element.alu(x: 7.2, y: 0.2, w: 1.8, h: 2.6, id: "alu", name: "ALU", name-anchor: "east", fill: _lt(_red))
  wire.wire("w1", ("rf-port-d1", "alu-port-in1"), style: "zigzag", bus: true)
  wire.wire("w2", ("rf-port-d2", "mux-port-in0"), style: "zigzag", bus: true)
  wire.wire("w3", ("imm-port-o", "mux-port-in1"), style: "zigzag", bus: true)
  wire.wire("w4", ("mux-port-out", "alu-port-in2"), style: "zigzag", bus: true)
  wire.stub("alu-port-out", "east", name: "result", length: 1.2)
})

// zap: standards-style electronic circuits (RC low-pass). Gotchas: component
// names are positional (name, node-a, node-b); `label:` takes content; wire()
// takes points only.
#let demo-zap() = zap.circuit({
  import zap: *
  vsource("V", (0, 0), (0, 3), label: $V_"in"$)
  wire((0, 3), (2.5, 3))
  resistor("R", (2.5, 3), (5, 3), label: $R$)
  capacitor("C", (5, 3), (5, 0), label: $C$)
  wire((5, 3), (7, 3))
  wire((5, 0), (0, 0))
  node("out", (7, 3), label: $V_"out"$)
  ground("g", (2.5, 0))
})

// digidraw (primary timing-diagram pick): WaveDrom syntax from a Typst dict,
// Typst markup in bus labels, themable. Gotcha: `data:` is an array of
// content/strings, one per bus segment; wave chars: p clock, 0/1, x, 2-9 bus.
#let demo-digidraw() = dd.wave((signal: (
  (wave: "p.......", name: "clk"),
  (wave: "01.0....", name: "req"),
  (wave: "x.3.4.5x", name: "addr", data: ([A0], [A1], [A2])),
  (wave: "0..1.0..", name: "ack"),
)))

// wavy (alternative): raw WaveDrom JSON5 string rendered via wasm. Faster to
// paste from wavedrom.com, but no Typst markup in labels and little styling.
#let demo-wavy() = wavy.render(
  "{signal:[{name:'clk',wave:'p......'},{name:'bus',wave:'x.34.5x',data:'head body tail'},{name:'wire',wave:'0.1..0.'}]}",
)

// k-mapper (Karnaugh pick: documented, 2-4 vars). Gotchas: manual-terms must
// list ALL 2^n cells in MINTERM order (not screen order); implicants are
// (top-left-minterm, bottom-right-minterm) rectangles. f = B C' + B D.
#let demo-kmap() = karnaugh(
  "4x4",
  labels: ($A$, $B$, $C$, $D$),
  manual-terms: (0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1),
  implicants: ((4, 13), (5, 15)),
)

// truthfy: truth table from expressions. Gotcha: pass math content, one
// column per expression; variables are auto-detected; `#` inside needs escaping.
#let demo-truthtable() = truth-table($A and B$, $A or B$, $A xor B$, $not (A and B)$)

// finite: DFA/NFA from a transition dict. Gotchas: keys are state names,
// values map target -> label (use "0,1" strings for multiple symbols);
// `none` = no outgoing edges; `final:` and `initial:` are state-name strings.
// This DFA accepts binary strings whose number of 1s is divisible by 3.
#let demo-dfa() = automaton(
  (
    q0: (q0: "0", q1: "1"),
    q1: (q1: "0", q2: "1"),
    q2: (q2: "0", q0: "1"),
  ),
  initial: "q0",
  final: ("q0",),
  style: (
    q0: (fill: _lt(_green)),
    transition: (stroke: _ink + 0.8pt),
  ),
)

// ---------------------------------------------------------------------------
//  HAND-BUILT DIAGRAMS (cetz / fletcher)
// ---------------------------------------------------------------------------

// Stack frame + heap (x86-64 style). Gotchas: addresses fall as the stack grows
// down; draw cells with rect+content so labels stay centred; pointer arrow
// crosses the page, so keep the canvas wide.
#let demo-stack-heap() = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let cell(y, label, c, w: 4.6, x: 0) = {
    rect((x, y), (x + w, y - 0.8), fill: _lt(c), stroke: c + 0.9pt)
    content((x + w / 2, y - 0.4), text(size: 8.5pt)[#label])
  }
  content((1.5, 0.5), text(weight: "bold", fill: _blue)[Stack])
  content((8, 0.5), anchor: "west", text(weight: "bold", fill: _teal)[Heap])
  // main frame
  cell(0, [`int *p`], _blue)
  cell(-0.8, [`int x = 7`], _blue)
  // foo frame
  cell(-1.6, [arg `n = 3`], _green)
  cell(-2.4, [return address], _red)
  cell(-3.2, [saved `rbp`], _red)
  cell(-4.0, [`char buf[8]`], _teal)
  // frame brackets (right of the stack)
  line((4.85, 0), (4.85, -1.6), stroke: _blue + 1.2pt)
  content((5.2, -0.8), angle: -90deg, text(size: 8pt, fill: _blue)[main])
  line((4.85, -1.6), (4.85, -4.8), stroke: _green + 1.2pt)
  content((5.2, -3.2), angle: -90deg, text(size: 8pt, fill: _green)[foo])
  // rbp / rsp markers (left)
  line((-1.9, -3.2), (-0.15, -3.2), mark: (end: "stealth", fill: _ink), stroke: _ink)
  content((-2.4, -3.2), text(size: 8.5pt)[`rbp`])
  line((-1.9, -4.8), (-0.15, -4.8), mark: (end: "stealth", fill: _ink), stroke: _ink)
  content((-2.4, -4.8), text(size: 8.5pt)[`rsp`])
  content((-2.4, 0.2), text(size: 7.5pt, fill: luma(110))[high addr])
  content((-2.4, -5.6), text(size: 7.5pt, fill: luma(110))[low addr])
  line((2.3, -5.3), (2.3, -6.3), mark: (end: "stealth", fill: _blue), stroke: _blue)
  content((3.2, -5.8), anchor: "west", text(size: 8pt, fill: _blue)[grows down])
  // heap
  cell(0, [malloc(12) · `[3|1|4]`], _teal, w: 4.6, x: 8)
  cell(-1.6, [free chunk], _bg, w: 4.6, x: 8)
  cell(-2.8, [malloc(32)], _teal, w: 4.6, x: 8)
  rect((8, -1.6), (12.6, -2.4), fill: none, stroke: (dash: "dashed", paint: luma(150)))
  // pointer p -> heap block
  line((4.0, 0), (4.0, 1.2), (10.3, 1.2), (10.3, 0),
    mark: (end: "stealth", fill: _red), stroke: _red + 1.1pt)
  content((7.1, 1.45), text(size: 8pt, fill: _red)[`p` points into the heap])
})

// 5-stage RISC pipeline with a load-use hazard: one bubble + forwarding.
// Gotcha: draw per-row with an offset in cycles; stalls are red cells.
#let demo-pipeline() = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let w = 1.15
  let h = 0.7
  let stage(r, c, s, fill: _lt(_blue), stroke: _blue) = {
    rect((c * w, -r * 1.0), ((c + 1) * w, -r * 1.0 - h), fill: fill, stroke: stroke + 0.8pt, radius: 2pt, name: "c" + str(r) + "-" + str(c))
    content(((c + 0.5) * w, -r * 1.0 - h / 2), text(size: 8pt, weight: "bold", fill: stroke)[#s])
  }
  let st = ("IF", "ID", "EX", "MEM", "WB")
  // header: cycles
  for c in range(9) { content(((c + 0.5) * w, 0.45), text(size: 8pt, fill: luma(110))[#(c + 1)]) }
  // lw
  for (i, s) in st.enumerate() { stage(0, i, s) }
  content((-0.2, -h / 2), anchor: "east", text(size: 8.5pt)[`lw  x2,0(x1)`])
  // add (stalls in ID for 1 cycle)
  stage(1, 1, "IF")
  stage(1, 2, "ID")
  stage(1, 3, "stall", fill: _lt(_red), stroke: _red)
  stage(1, 4, "EX", fill: _lt(_green), stroke: _green)
  stage(1, 5, "MEM")
  stage(1, 6, "WB")
  content((-0.2, -1 - h / 2), anchor: "east", text(size: 8.5pt)[`add x4,x2,x3`])
  // sub (held in IF)
  stage(2, 2, "IF")
  stage(2, 3, "stall", fill: _lt(_red), stroke: _red)
  stage(2, 4, "ID")
  stage(2, 5, "EX")
  stage(2, 6, "MEM")
  stage(2, 7, "WB")
  content((-0.2, -2 - h / 2), anchor: "east", text(size: 8.5pt)[`sub x6,x4,x5`])
  // forwarding arrow: lw MEM (cycle 4) -> add EX (cycle 5)
  line("c0-3.south", "c1-4.north", mark: (end: "stealth", fill: _green), stroke: _green + 1.2pt)
  content((5.1 * w, -0.55), anchor: "west", text(size: 8pt, fill: _green)[forward MEM → EX\ (loaded value skips WB)])
  content((0, -3.5), anchor: "west", text(size: 8pt, fill: _red)[load-use hazard: `add` needs `x2` one cycle before `lw` has it → 1 bubble, then forward MEM → EX])
})

// 2-way set-associative cache lookup. Gotcha: arrows from address fields to
// the selected set / comparators are drawn by hand; adapt rows to your sizes.
#let demo-cache-lookup() = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let box(a, b, label, c, name: none) = {
    rect(a, b, fill: _lt(c), stroke: c + 0.9pt, name: name)
    content(((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2), text(size: 8.5pt)[#label])
  }
  // address
  box((0, 0), (4, 0.9), [Tag (18)], _blue, name: "tag")
  box((4, 0), (6.4, 0.9), [Index (6)], _teal, name: "idx")
  box((6.4, 0), (8.6, 0.9), [Offset (6)], _green, name: "off")
  content((-0.2, 0.45), anchor: "east", text(size: 8.5pt)[address])
  // sets
  for i in range(4) {
    let y = -1.8 - i * 0.85
    let sel = i == 2
    let st = if sel { _teal } else { luma(150) }
    rect((4, y), (6.4, y - 0.7), fill: if sel { _lt(_teal) } else { _bg }, stroke: st + 0.8pt)
    content((5.2, y - 0.35), text(size: 8pt, fill: st)[set #i])
    for (w, x0) in ((0, 7), (1, 11)) {
      rect((x0, y), (x0 + 0.7, y - 0.7), fill: _bg, stroke: st + 0.6pt)
      rect((x0 + 0.7, y), (x0 + 2.4, y - 0.7), fill: if sel { _lt(_blue) } else { _bg }, stroke: st + 0.6pt, name: "t" + str(w) + "-" + str(i))
      rect((x0 + 2.4, y), (x0 + 3.5, y - 0.7), fill: _bg, stroke: st + 0.6pt)
      content((x0 + 0.35, y - 0.35), text(size: 7pt, fill: st)[V])
      content((x0 + 1.55, y - 0.35), text(size: 7pt, fill: st)[tag])
      content((x0 + 2.95, y - 0.35), text(size: 7pt, fill: st)[data])
    }
  }
  content((8.9, -1.5), text(size: 8pt, fill: _blue, weight: "bold")[way 0])
  content((12.9, -1.5), text(size: 8pt, fill: _blue, weight: "bold")[way 1])
  // index -> selected set (routed in the gap right of the set column)
  line((6.0, 0), (6.0, -1.0), (6.7, -1.0), (6.7, -4.1), (6.4, -4.1), mark: (end: "stealth", fill: _teal), stroke: _teal + 1.1pt)
  // comparators + hit
  box((8.5, -6.0), (9.5, -6.7), [=], _red, name: "cmp0")
  box((12.5, -6.0), (13.5, -6.7), [=], _red, name: "cmp1")
  box((10.2, -6.0), (12.0, -6.7), [OR = hit], _green, name: "hit")
  line("t0-2.south", (8.9, -4.45), (9.0, -6.0), mark: (end: "stealth", fill: _ink), stroke: _ink)
  line("t1-2.south", (13.0, -4.45), (13.0, -6.0), mark: (end: "stealth", fill: _ink), stroke: _ink)
  line((9.5, -6.35), (10.2, -6.35), mark: (end: "stealth", fill: _ink), stroke: _ink)
  line((12.5, -6.35), (12.0, -6.35), mark: (end: "stealth", fill: _ink), stroke: _ink)
  // address tag fans into both comparators from below
  line((2, 0), (2, -7.2), (13.0, -7.2), stroke: (paint: _blue, dash: "dashed"))
  line((9.0, -7.2), (9.0, -6.7), mark: (end: "stealth", fill: _blue), stroke: _blue)
  line((13.0, -7.2), (13.0, -6.7), mark: (end: "stealth", fill: _blue), stroke: _blue)
  content((2.2, -8.1), anchor: "west", text(size: 8.5pt)[tag compared with both ways of the set; hit if V=1 and tags equal\ miss: evict (LRU) and fetch the block from the next level])
})

// Memory hierarchy as a widening stack. Gotcha: widths encode capacity only
// qualitatively; latencies are typical orders of magnitude, edit to taste.
#let demo-memory-hierarchy() = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let rows = (
    ("Registers", "< 1 ns", "~1 KB", _red),
    ("L1 cache", "~1 ns", "32 KB", _red),
    ("L2 cache", "~4 ns", "512 KB", _blue),
    ("L3 cache", "~15 ns", "32 MB", _blue),
    ("DRAM", "~80 ns", "16 GB", _teal),
    ("SSD", "~100 µs", "1 TB", _green),
  )
  for (i, r) in rows.enumerate() {
    let w = 2.2 + i * 1.1
    let y = -i * 0.95
    rect((-w / 2, y), (w / 2, y - 0.8), fill: _lt(r.at(3)), stroke: r.at(3) + 0.9pt, radius: 3pt)
    content((0, y - 0.4), text(size: 9pt, weight: "bold", fill: r.at(3))[#r.at(0)])
    content((-4.8, y - 0.4), anchor: "east", text(size: 8.5pt)[#r.at(2)])
    content((4.8, y - 0.4), anchor: "west", text(size: 8.5pt)[#r.at(1)])
  }
  content((-4.8, 0.5), anchor: "east", text(size: 8pt, fill: luma(110))[capacity ↓])
  content((4.8, 0.5), anchor: "west", text(size: 8pt, fill: luma(110))[latency ↑])
  line((-6.0, 0), (-6.0, -5.2), mark: (end: "stealth", fill: luma(120)), stroke: luma(120))
  content((-6.4, -2.6), angle: 90deg, text(size: 8pt, fill: luma(110))[larger, slower, cheaper per bit])
})

// x86-64 4-level page-table walk. Gotcha: fletcher node names are labels
// (<name>); edges label with the entry used; keep `spacing` generous.
#let demo-page-walk() = {
  let n = node.with(shape: rect, corner-radius: 3pt)
  diagram(
    node-stroke: 0.9pt, spacing: (17mm, 12mm), node-inset: 6pt, edge-stroke: 0.9pt,
    // virtual address fields
    n((0, 0), text(size: 7.5pt)[PML4 idx\ (9)], fill: _lt(_blue), stroke: _blue, name: <f0>),
    n((1, 0), text(size: 7.5pt)[PDPT idx\ (9)], fill: _lt(_blue), stroke: _blue, name: <f1>),
    n((2, 0), text(size: 7.5pt)[PD idx\ (9)], fill: _lt(_blue), stroke: _blue, name: <f2>),
    n((3, 0), text(size: 7.5pt)[PT idx\ (9)], fill: _lt(_blue), stroke: _blue, name: <f3>),
    n((4, 0), text(size: 7.5pt)[offset\ (12)], fill: _lt(_green), stroke: _green, name: <fo>),
    // tables
    n((0, 2), [PML4], fill: _lt(_teal), stroke: _teal, name: <t0>),
    n((1, 2), [PDPT], fill: _lt(_teal), stroke: _teal, name: <t1>),
    n((2, 2), [PD], fill: _lt(_teal), stroke: _teal, name: <t2>),
    n((3, 2), [PT], fill: _lt(_teal), stroke: _teal, name: <t3>),
    n((4, 2), text(size: 8pt)[physical\ frame], fill: _lt(_green), stroke: _green, name: <pf>),
    n((-1, 2), text(size: 9pt)[`CR3`], fill: _bg, stroke: _ink, name: <cr3>),
    edge(<f0>, <t0>, "->"), edge(<f1>, <t1>, "->"), edge(<f2>, <t2>, "->"), edge(<f3>, <t3>, "->"),
    edge(<fo>, <pf>, "->", label: text(size: 7pt)[plus offset], label-side: right),
    edge(<cr3>, <t0>, "->"),
    edge(<t0>, <t1>, "->", stroke: _red), edge(<t1>, <t2>, "->", stroke: _red),
    edge(<t2>, <t3>, "->", stroke: _red), edge(<t3>, <pf>, "->", stroke: _red),
  )
  // red arrows: each entry holds the base of the next table (4 reads; TLB caches the result)
}

// MPI point-to-point + broadcast as a time-lines diagram. Gotcha: time runs
// downward; message arrows slope down to show latency.
#let demo-mpi-sendrecv() = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  for r in range(4) {
    let x = r * 3.2
    content((x, 0.6), text(weight: "bold", fill: _blue, size: 9pt)[rank #r])
    line((x, 0.2), (x, -8), stroke: (paint: luma(150), dash: "dashed"))
  }
  let busy(r, y0, y1, c) = rect((r * 3.2 - 0.18, y0), (r * 3.2 + 0.18, y1), fill: _lt(c), stroke: c + 0.7pt)
  busy(0, -0.5, -1.4, _teal)
  busy(1, -0.5, -2.4, _teal)
  let msg(a, ya, b, yb, lbl, c: _red, side: "north") = {
    line((a * 3.2 + 0.18, ya), (b * 3.2 - 0.18, yb), mark: (end: "stealth", fill: c), stroke: c + 1.1pt, name: "m")
    content("m.mid", anchor: "south", padding: 0.12, angle: -19deg, text(size: 7.5pt, fill: c)[#lbl])
  }
  msg(0, -1.4, 1, -2.4, [`MPI_Send(tag 7)`])
  busy(1, -2.4, -3.0, _green)
  content((1 * 3.2 + 0.4, -2.7), anchor: "west", text(size: 7.5pt, fill: _green)[`MPI_Recv`])
  // broadcast from rank 0
  busy(0, -4.2, -5.0, _blue)
  content((0.4, -4.6), anchor: "west", text(size: 7.5pt, fill: _blue)[`MPI_Bcast`])
  for r in (1, 2, 3) {
    line((0.18, -5.0), (r * 3.2 - 0.18, -5.0 - r * 0.9), mark: (end: "stealth", fill: _blue), stroke: _blue + 1pt)
  }
  // barrier
  line((-0.6, -7.3), (3 * 3.2 + 0.6, -7.3), stroke: (paint: _red, thickness: 1.4pt))
  content((3 * 3.2 + 0.8, -7.3), anchor: "west", text(size: 8pt, fill: _red)[`MPI_Barrier`])
})

// MPI_Allreduce(SUM) via reduce tree + broadcast. Gotcha: two small
// diagrams side by side; each rank node keeps its local value inside.
#let demo-mpi-allreduce() = {
  let rk(p, r, v, c) = node(p, text(size: 8.5pt)[*r#r*\ #v], shape: circle, fill: _lt(c), stroke: c, name: label("r" + str(r) + str(v)))
  grid(
    columns: 2, column-gutter: 3em, align: top,
    [
      #align(center, text(size: 9pt, fill: _blue, weight: "bold")[1 · reduce up]) #v(-0.4em)
      #diagram(
        node-stroke: 0.9pt, spacing: (13mm, 13mm), edge-stroke: 0.9pt,
        node((0, 2), [*r0*\ 3], shape: circle, fill: _lt(_teal), stroke: _teal, name: <a>),
        node((1, 2), [*r1*\ 1], shape: circle, fill: _lt(_teal), stroke: _teal, name: <b>),
        node((2, 2), [*r2*\ 4], shape: circle, fill: _lt(_teal), stroke: _teal, name: <c>),
        node((3, 2), [*r3*\ 1], shape: circle, fill: _lt(_teal), stroke: _teal, name: <d>),
        node((0.5, 1), [4], shape: circle, fill: _lt(_blue), stroke: _blue, name: <ab>),
        node((2.5, 1), [5], shape: circle, fill: _lt(_blue), stroke: _blue, name: <cd>),
        node((1.5, 0), [9], shape: circle, fill: _lt(_red), stroke: _red, name: <root>),
        edge(<a>, <ab>, "->"), edge(<b>, <ab>, "->"), edge(<c>, <cd>, "->"), edge(<d>, <cd>, "->"),
        edge(<ab>, <root>, "->"), edge(<cd>, <root>, "->"),
      )
    ],
    [
      #align(center, text(size: 9pt, fill: _green, weight: "bold")[2 · broadcast down]) #v(-0.4em)
      #diagram(
        node-stroke: 0.9pt, spacing: (13mm, 13mm), edge-stroke: 0.9pt,
        node((1.5, 0), [9], shape: circle, fill: _lt(_red), stroke: _red, name: <root>),
        node((0.5, 1), [9], shape: circle, fill: _lt(_blue), stroke: _blue, name: <ab>),
        node((2.5, 1), [9], shape: circle, fill: _lt(_blue), stroke: _blue, name: <cd>),
        node((0, 2), [*r0*\ 9], shape: circle, fill: _lt(_green), stroke: _green, name: <a>),
        node((1, 2), [*r1*\ 9], shape: circle, fill: _lt(_green), stroke: _green, name: <b>),
        node((2, 2), [*r2*\ 9], shape: circle, fill: _lt(_green), stroke: _green, name: <c>),
        node((3, 2), [*r3*\ 9], shape: circle, fill: _lt(_green), stroke: _green, name: <d>),
        edge(<root>, <ab>, "->"), edge(<root>, <cd>, "->"),
        edge(<ab>, <a>, "->"), edge(<ab>, <b>, "->"), edge(<cd>, <c>, "->"), edge(<cd>, <d>, "->"),
      )
    ],
  )
}

// Process state machine. Gotcha: self-contained fletcher diagram; use `bend:`
// to separate the two opposite edges between Ready and Running.
#let demo-process-states() = diagram(
  node-stroke: 0.9pt, spacing: (30mm, 22mm), node-inset: 8pt, edge-stroke: 0.9pt,
  node-corner-radius: 10pt,
  node((0, 0), [New], fill: _bg, stroke: luma(140), name: <new>),
  node((1, 0), [Ready], fill: _lt(_blue), stroke: _blue, name: <ready>),
  node((2, 0), [Running], fill: _lt(_green), stroke: _green, name: <run>),
  node((3, 0), [Terminated], fill: _bg, stroke: luma(140), name: <term>),
  node((1.5, 1.8), [Waiting (blocked)], fill: _lt(_red), stroke: _red, name: <wait>),
  edge(<new>, <ready>, "->", label: text(size: 7.5pt)[admit]),
  edge(<ready>, <run>, "->", bend: 28deg, label: text(size: 7.5pt)[dispatch]),
  edge(<run>, <ready>, "->", bend: 28deg, label: text(size: 7.5pt)[preempt / yield]),
  edge(<run>, <term>, "->", label: text(size: 7.5pt)[exit]),
  edge(<run>, <wait>, "->", label: text(size: 7.5pt)[I/O or lock wait], label-side: right),
  edge(<wait>, <ready>, "->", label: text(size: 7.5pt)[I/O done], label-side: left),
)

// TCP three-way handshake as a sequence diagram. Gotcha: arrows slope to
// show propagation delay; state names sit beside the lifelines.
#let demo-tcp-handshake() = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let (xc, xs) = (0, 8)
  content((xc, 0.6), text(weight: "bold", fill: _blue)[Client])
  content((xs, 0.6), text(weight: "bold", fill: _teal)[Server])
  line((xc, 0.2), (xc, -6.8), stroke: (paint: luma(150), dash: "dashed"))
  line((xs, 0.2), (xs, -6.8), stroke: (paint: luma(150), dash: "dashed"))
  let st(x, y, s, side, c) = content((x, y), anchor: side, padding: 0.2, text(size: 7.5pt, fill: c, font: "DejaVu Sans Mono")[#s])
  st(xc, -0.2, "CLOSED", "east", luma(120))
  st(xs, -0.2, "LISTEN", "west", luma(120))
  let m(ya, yb, dir, lbl, c, name) = {
    let (a, b) = if dir == 1 { (xc, xs) } else { (xs, xc) }
    line((a, ya), (b, yb), mark: (end: "stealth", fill: c), stroke: c + 1.2pt, name: name)
    content(name + ".mid", anchor: "south", padding: 0.12, angle: if dir == 1 { -8deg } else { 8deg }, text(size: 8pt, fill: c)[#lbl])
  }
  m(-0.8, -1.8, 1, [SYN, seq = x], _blue, "a")
  st(xc, -0.8, "SYN_SENT", "east", _blue)
  m(-2.4, -3.4, -1, [SYN+ACK, seq = y, ack = x+1], _teal, "b")
  st(xs, -1.8, "SYN_RCVD", "west", _teal)
  m(-4.0, -5.0, 1, [ACK, ack = y+1], _green, "c")
  st(xc, -4.0, "ESTABLISHED", "east", _green)
  st(xs, -5.0, "ESTABLISHED", "west", _green)
  content((xs / 2, -6.4), text(size: 8.5pt, fill: luma(90))[data can flow in both directions])
})
