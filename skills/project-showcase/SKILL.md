---
name: project-showcase
description: >-
  Turn any repo into a public presence: a bespoke landing page designed around what the project is (not a template), a searchable usage guide, a visually designed README, real screenshots and clips, GitHub repo metadata (description, topics, website), published to GitHub Pages. Brainstorms the concept with the user first, then builds whatever fits the project, from SVG motion and video to Three.js scenes and custom navigation. Use when the user wants to document a project, make a landing page or project site, write a usage guide, beautify or redesign a README, set the GitHub repo description/topics, add screenshots/GIFs/demo videos, set up GitHub Pages, or "make this project look good", even if they only name one of those pieces.
---

# Project showcase

Produces, from the repo itself: a landing page with its own concept and look, a searchable usage guide rendered from the repo's markdown, a beautified README, repo metadata, real captures, and a GitHub Pages deploy.

Two layers, kept apart on purpose:
- **Rails (fixed, boring, reliable):** guide rendering, search, base path, Pages workflow, verify/smoke scripts. Reuse as-is.
- **Landing page (free, never templated):** concept, layout, navigation, type, palette, motion, 3D, media. Designed per project. Nothing in `src/components/` is a default; it is a parts bin.

No required sections. No hero, quickstart, feature proof, screenshot or footer unless the concept calls for it. An animation, a 3D scene, one long essay, a playable demo or a single typeset page can be the whole site.

A landing page that could belong to any other project is a failed build, even if every check passes.

## Workflow

### 1. Inspect (read-only, narrow)
Read README, manifest, `docs/`, existing screenshots, how to run it, `git remote`. Note what exists. Never read `.env*`. Jot what the project *feels like* (a tool for night-shift sysadmins? a playful game engine? a quiet math library?).

### 2. Brainstorm with the user
Do not scaffold yet. Follow references/creative-direction.md:
1. **Research references** (creative-direction.md > Where to look): study 3-5 real sites relevant to the concept, note what to borrow (the idea, never the code or art).
2. **Ask** with AskUserQuestion (2-4 questions per call, skip what the repo answers): audience and the one action they should take, scope (landing / guide / README / media / publish), personality and what to avoid, sites they admire, what can be captured or run, hosting.
3. **Propose 3 genuinely different directions** (concept, metaphor, palette, type, signature moment, tech). Use AskUserQuestion `preview` to show each side by side. Mixing is fine.
4. **Write the brief** (Goal / Constraints / Acceptance / Concept / Signature moment / Toolbox / Media plan / Unresolved questions) and get a yes.

### 3. Scaffold the rails
Run `scripts/init.sh <project-root>`: copies the Astro template to `site/`, the Pages workflow, and fills owner/repo from `git remote`. It refuses to overwrite. Tiny repo with no docs: plain HTML is fine, skip node; still run the sameness check.

### 4. Build the landing page from scratch
Replace the stub `src/pages/index.astro` (and `404.astro`). One page or many: add `src/pages/<name>.astro` for an about/gallery/demo/changelog page whenever the concept wants it, all on `Landing.astro` with a shared nav component of your own. Smoke tests cover every extra page. It uses `layouts/Landing.astro` (head and meta only: no header, footer, fonts or global CSS), so the page owns its navigation, type, palette and structure. Pick tools from references/toolbox.md by what the project needs: SVG/CSS motion, scroll storytelling, video, canvas/WebGL, a Three.js model, a live in-browser demo, a different nav paradigm, a different aesthetic entirely. Look things up before using them (`ctx7 library`, `ctx7 docs`, web search for components and inspiration); never guess an API. If installed, lean on `design-taste-frontend` or `impeccable` for art direction and the look-and-fix loop.

Hard requirements (smoke tests enforce them): an `<h1>` in the HTML, visible with JS off and under reduced motion (any styling, even tiny or typographic); no horizontal overflow at 375/768/1440; a visible link to `guide/` via `withBase`; no placeholder images; no console errors. Heavy things load lazily and have a static fallback.

### 5. Make the guide feel like the same site
The guide keeps its own layout. Re-skin it to the landing's identity: edit tokens and fonts in `src/styles/global.css` and swap the font imports in `layouts/Base.astro`. Guide content is the repo's own markdown (Quickstart, task-based Usage, Configuration, Troubleshooting/FAQ, Contributing); create thin ones only when missing. `site.config.mjs` `guide` globs control what renders. See references/content-contract.md for truth and voice rules.

### 6. Media
Follow references/media.md: edit `site/scripts/capture.mjs`, record on synthetic data only, name shots by content, convert clips small. CLI/TUI: terminal recording. Media may also be generated art (SVG, canvas, 3D) when the project has no UI.

### 7. README (beautified)
Redesign the README as part of the showcase, built on the same concept as the landing page. If `beautify-github-readme` is installed, follow it in README mode (full redesign or visual refresh); otherwise apply the rules below.
- Write first: Audience / One-sentence value / Primary proof / First successful action / Visual theme. No invented adoption, benchmarks or features.
- Order: hero (name + plain-language value, built from project content, not a generic banner) > real proof (screenshot, output, clip) > what it is > how it works > install + first command > limits/license/contributing. Example before explanation.
- Visual layer: GitHub-safe SVG (1200 viewBox, `width="100%"`, system fonts, alt text, no scripts/`foreignObject`/remote fonts); PNG/WebP for screenshots; GIF only for approved motion, with static SVG fallback. Assets in `assets/readme/`. Text, commands and links stay Markdown. Motif derived from the project, same palette/type as the landing page.
- Link to the site and guide; claims match the landing page. Do not duplicate guide content. Must still read well when images fail.
- Check: `python3 scripts/audit_readme.py README.md`, then view hero and section transitions at GitHub width, light and dark.
- Optional "README MADE WITH" attribution or showcase PR: only if the user asks.

### 8. Verify (all must pass before "done"; bar in creative-direction.md > Proper)
From `site/`: `npm install && npx astro check && npm run build && npm run verify`, then `npm run preview -- --host 127.0.0.1 --port 4321` and `npm test`. If chrome-devtools is available also run a Lighthouse audit on the built site. Then look at the full-page captures in `test-results/site/` and run the sameness check from references/creative-direction.md. Passing scripts do not mean it looks right.

### 9. Publish (ask first)
Pushing and enabling Pages are outward-facing: confirm, then follow references/publishing.md (Settings > Pages > Source: GitHub Actions; push to main).

### 10. Repo metadata (ask first, outward-facing)
After the site URL is known, propose exact values, get a yes, then run:
`gh repo edit --description "<one line, <=120 chars, plain value statement>" --homepage "<Pages URL>" --add-topic a,b,c`
- Description matches the README's one-sentence value. Topics: 5-10 lowercase, hyphenated, from language, domain, platform, tool type. Check current with `gh repo view --json description,homepageUrl,repositoryTopics`.
- Optionally suggest a social preview image (1280x640; upload in Settings, no CLI) from the hero art.
- Also check: LICENSE present, Issues/Discussions on as wanted, README badges (build, license, site) only if real.

## Tweaking
Project facts live in `site.config.mjs`. Identity lives in the landing page and `global.css` tokens. The scripts in `site/scripts/` are rails: edit `capture.mjs` per project, leave `verify.mjs` and `smoke.mjs` alone.
