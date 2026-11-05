# Rich visuals (3D, hero figures, polished plots)

Use when the user chose **balanced** or **rich** visuals, or the track is
Typst+embedded / HTML. Make the visual outside Typst, render to PNG, embed.

## Three.js / canvas / SVG to PNG (verified: chromium 3D render works headless)

1. Write `figs-src/<name>.html` (Three.js from cdnjs, e.g. `three@r128`; use
   `preserveDrawingBuffer:true`, white or transparent background, fixed size).
2. Render:
   `chromium --headless=new --no-sandbox --use-angle=swiftshader --enable-unsafe-swiftshader --allow-file-access-from-files --virtual-time-budget=8000 --window-size=1200,800 --screenshot=figs/<name>.png file://$PWD/figs-src/<name>.html`
   (swiftshader = software WebGL; without it 3D may render blank).
3. Look at the PNG (Read). Crop/adjust, then embed:
   `#figure(image("figs/<name>.png", width: 80%), caption: [what to notice])`
4. In the HTML track, drop the same file in the `.hero` div or inline the canvas.

Good targets: loss surfaces + descent paths, vector fields, geometric solids,
Bloch sphere, 3D scatter/decision boundaries, network layer stacks.
Style: palette from `template.typ` (`#2f5d8a`, `#3b7a78`, `#b04a3f`...), no
default rainbow unless it encodes data, label on the figure, no chart junk.

## Python plots (optional)
`uv run --with matplotlib --with numpy fig.py` (matplotlib is not installed
globally). Save `dpi=250`, `bbox_inches="tight"`, same palette. Untested here:
run once and Read the PNG before using.

## Hero figure per chapter
One figure that sums up the chapter (a surface, path, diagram), 80% width, under
the `chapter-cover` pills. It may be decorative-but-true: never a random image.
