# Toolbox

Choose by what the project needs, not by what is impressive. Each pick gets a fallback. Look up current APIs first: `ctx7 library <name> <query>`, then `ctx7 docs <id> <query>`. Pin versions.

## Match need to technique
| The project is / needs | Consider |
|---|---|
| Has a mechanism worth explaining | Inline SVG diagram with stroke-draw or stepped state (GSAP, CSS, SMIL-free); scroll-driven story (GSAP ScrollTrigger or CSS `animation-timeline: scroll()`) |
| Has a visual output (graphics, audio, data, simulation) | Make the output the hero: canvas/WebGL/WebGPU render of the real thing; shader background that reacts to the cursor (ogl or twgl for light weight) |
| Physical, spatial, hardware, robotics, 3D | Three.js (or react-three-fiber if already React) with a glTF model; orbit on drag, scroll-linked camera; Draco/meshopt-compress |
| CLI / TUI | xterm.js or a hand-built terminal replaying a real recorded session (asciinema cast, vhs tape) with copy buttons; or a typeset man-page aesthetic |
| Library / API | Live, editable snippet running in the browser (WASM build, Pyodide, a web worker); before/after code diff; REPL |
| Game / playful tool | Actual playable embed, sprite-sheet animation, pixel/CRT styling, sound off by default |
| Data / ML | Interactive chart of real results (D3, Observable Plot), model-in-browser demo (ONNX Runtime Web, transformers.js) |
| Pure writing / academic | Editorial typography, margin notes, animated equations (KaTeX plus CSS), one great figure |
| Has screenshots and flows | Video loops, device frames, scroll-synced step reveals, comparison slider |
| Needs a different shell | Side rail, bottom dock, command palette (`cmdk` style), floating section index, horizontal scroll sections, single-screen snap pages, or no nav at all |

Also in the box: View Transitions API, `@property` + CSS gradients, SVG filters, `mix-blend-mode`, variable fonts with axis animation, Lottie/dotLottie or Rive for authored vector motion, Canvas 2D particles, WebAudio (opt-in only), Lenis for smooth scroll (only if it earns its cost).

## Finding components and inspiration online
- Web search and `ctx7` for current docs. Inspiration: Awwwards, One Page Love, Codrops tutorials, CodePen, Dribbble, Mobbin; for the idea, not for copying.
- Copy-in component sources you can restyle: shadcn/ui, Magic UI, Aceternity UI, React Bits, 21st.dev, Origin UI. For Astro, prefer framework-free ports or small islands.
- Assets: Poly Pizza, Sketchfab (CC0 / CC-BY only), LottieFiles, Kenney, Google Fonts / Fontsource, unDraw-style art only if restyled. Record the license and attribution for everything not yours in `site/ASSETS.md`.
- Never ship code or art whose license you have not read.

## Integration rules (Astro on GitHub Pages)
- Static output only; every asset URL goes through `withBase()` or imports, so it works under `/repo/`.
- Heavy libraries (three, d3, wasm) are dynamic `import()`ed when the section nears the viewport (`IntersectionObserver` or `client:visible`). Keep the initial landing JS small (aim under about 150 KB gzipped, excluding lazy chunks).
- Every WebGL/canvas scene: feature-check, `prefers-reduced-motion` gives a still frame, `pointer: coarse` and low-memory devices get a lighter path or a poster image, pause when offscreen, `dispose()` on teardown, cap pixel ratio at 2.
- Models under about 2 MB, textures compressed, clips under about 1.5 MB each, fonts subset, `font-display: swap`.
- Self-host fonts and libraries (npm / Fontsource). No runtime CDN script tags.
- Content and the `<h1>` exist in HTML without JS. Motion enhances; it never gates reading.
- Contrast and focus rings hold in every state; interactive targets at least 44px; keyboard reaches everything; canvas has a text alternative.
- If an effect does not explain the project or reward the visitor, cut it.

## When not to
No 3D for a CLI that has nothing spatial. No scroll-jacking that fights the user. No autoplay audio. No effect that only exists because it was available.

## Recipes (verify current API with ctx7 before using)
- **Lazy heavy scene:** `const io = new IntersectionObserver(([e]) => { if (e.isIntersecting) { io.disconnect(); import("./scene.ts").then(m => m.start(canvas)); } }); io.observe(canvas);` Poster `<img>` inside the canvas wrapper as fallback.
- **Scroll-driven CSS (no JS):** `@supports (animation-timeline: scroll()) { .x { animation: reveal linear both; animation-timeline: view(); animation-range: entry 0% cover 40%; } }` Outside `@supports` the element stays fully visible.
- **Reduced motion gate:** `const still = matchMedia("(prefers-reduced-motion: reduce)").matches;` render one frame and skip the loop.
- **SVG stroke draw:** `path.style.strokeDasharray = path.style.strokeDashoffset = path.getTotalLength();` then animate offset to 0 (GSAP, WAAPI or scroll).
- **Pause offscreen:** same `IntersectionObserver`; cancel `requestAnimationFrame` when not intersecting.
