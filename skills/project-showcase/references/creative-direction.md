# Creative direction

The landing page gets its identity here, before any code. Spend real effort on this step; it is the difference between a site and a template.

## 1. Questions (AskUserQuestion, batch 2-4, skip what the repo answers)
- **Audience + action:** who lands here (users, contributors, graders, recruiters, investors) and the single thing they should do (install, star, try the demo, read the paper).
- **Personality:** pick words. Playful / austere / technical / warm / dramatic / retro / editorial / calm. What should it NOT feel like?
- **References:** sites, games, posters, products they love. Anything they hate.
- **Assets:** logo, palette, mascot, screenshots, existing brand? Can the project run locally on synthetic data? Does it have a web build, a CLI, a library API?
- **Appetite:** how far to go. Subtle motion, a scroll story, a 3D scene, a live in-browser demo. Effort and performance budget.
- **Scope + hosting:** landing / guide / README / media / publish; `owner.github.io/repo` or custom domain.

## 2. Three directions
Offer three that differ in concept, not in colour. Each: name, one-line metaphor, palette (2-4 colours, named), type pairing, layout and nav idea, the signature moment, tech needed, media needed. Show them with AskUserQuestion `preview` (ASCII layout sketch plus the specs). Recommend one and say why it fits this project.

Ways to find a concept:
- **Literalize the mechanism:** a build tool as a factory line, a scheduler as a train timetable, a parser as a sentence diagram, a backup tool as a vault door opening.
- **Borrow the user's world:** a tool for musicians looks like a score; for ops people, a pager-and-terminal control room; for students, a margin-scribbled notebook.
- **Pick a medium:** zine, blueprint, arcade cabinet, field guide, brutalist doc, museum placard, vintage manual, synth panel, newspaper front page.
- **Make the product the hero:** if it has a visual output, the output is the page (a shader, a rendered scene, a live widget), not a screenshot of it.
- **Quiet is a concept too:** a tiny library can be one beautifully typeset page with one animated diagram. Restraint chosen on purpose is not slop.

## 3. The brief (write it, get a yes)
**Goal / Constraints / Acceptance criteria / Unresolved questions**, plus:
- **Concept:** the idea in one sentence and the metaphor it comes from.
- **Signature moment:** the one thing a visitor remembers (a scroll-driven transformation, a 3D object that reacts to the cursor, a live demo, a typeset equation that animates).
- **Look:** palette, type, spacing feel, nav pattern (top bar, side rail, dock, command palette, floating index, none).
- **Toolbox:** chosen from toolbox.md with a reason each; fallback for each.
- **Media plan:** what gets captured, drawn, rendered, or recorded.
- **Budget:** initial JS, total weight, devices.

## 4. Sameness check (before calling it done)
1. **Swap test:** put another project's name and tagline in. Still plausible? Redo the concept.
2. **Default audit:** each of these needs a reason rooted in the project, otherwise change it: centered hero with a gradient headline and two buttons; glass sticky navbar; three icon cards; big-number stat row; purple/blue gradient; Inter/Noto/system font; alternating image-text zebra; footer of four link columns.
3. **Squint test:** blur the screenshot. Is there a clear focal point and rhythm, or evenly weighted blocks?
4. **One-word test:** ask a stranger-proxy (yourself, cold) what the site feels like in one word. If it is "clean" or "modern", it has no personality.

Rules that stay: truth and voice in content-contract.md, accessibility, no horizontal overflow, content visible without JS.

## Concept gallery (to spark ideas, never to copy)
| Project | A direction that would fit |
|---|---|
| Build tool / CI | One continuous SVG conveyor line you scrub with scroll; each stage lights up with the real log line |
| Parser / compiler | The page is a sentence being parsed: tokens, tree and output morph as you scroll |
| Database / storage | A 3D stack of pages or blocks you can rotate; queries as light paths through it |
| Game engine / game | The landing page is a playable level; docs hide behind a pause menu |
| Robotics / hardware | Orbitable glTF model with callouts; sensors animate on hover |
| CLI tool | Full-bleed terminal that types its own tour from a real recorded session; nav is a command prompt |
| Math / science library | Editorial paper layout, margin notes, one live plot that responds to a slider |
| Design / graphics tool | The output is the page: a shader or canvas that reacts to the cursor |
| Data / ML | Scroll-driven chart of real results; in-browser model demo |
| Small utility | One screen, one sentence, one animated diagram, nothing else |
| Dotfiles / config | A zine or desk-setup illustration; hover a part to see its config |
| Learning project | A lab notebook or field guide with hand-drawn SVG and dated entries |

## Where to look (research before proposing directions)
Use WebSearch / WebFetch, or chrome-devtools to open and screenshot a site. Study 3-5, write down what idea each gives you. Take the idea, never the code, copy or art.
- **Whole-site inspiration:** awwwards.com, onepagelove.com, godly.website, siteinspire.com, land-book.com, httpster.net, lapa.ninja, minimal.gallery
- **Motion and interaction:** tympanus.net/codrops, codepen.io, motion.dev, gsap.com showcase
- **3D and shaders:** threejs.org/examples, shadertoy.com, thebookofshaders.com, sketchfab.com, poly.pizza
- **Type:** typewolf.com, fontsinuse.com, fonts.google.com, fontshare.com
- **Colour:** realtimecolors.com, coolors.co
- **Layout and art direction:** dribbble.com, behance.net, mobbin.com
- **Component sources:** 21st.dev, reactbits.dev, magicui.design, ui.aceternity.com
- **Peers:** the project's own category (search "<kind of project> landing page", GitHub trending, awesome-lists) to see what the genre does so you can break it on purpose.
Sites change; if one is down or stale, search for its successor.

## Proper (the bar for "done")
- No TODO, lorem, placeholder image, dead link or empty section (verify.mjs fails these).
- Semantic HTML: one h1, landmark regions, real `<a>`/`<button>`, alt text, labelled controls; keyboard-only and screen-reader pass on the signature interaction.
- Responsive at 375/768/1440; touch targets 44px; no horizontal overflow; reduced-motion and no-JS paths.
- Per-page `<title>`, description, canonical and OG tags; an OG image (a rendered still of the signature moment); favicon; a 404 in the site's voice.
- Performance: Lighthouse mobile performance 90+ and accessibility 95+ as the target on the built site; heavy assets lazy; no layout shift from late fonts or media.
- Every claim true of the default branch; credits and licenses for third-party art, models, fonts in `site/ASSETS.md`.
