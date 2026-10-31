# Parts bin and pulling in more

Optional parts, not defaults. The landing page is designed from the brief (creative-direction.md, toolbox.md); reach for these only when one fits the concept. Guide pages use them freely.

Bundled (in `src/components/`): Hero, Chapter, Steps, Terminal, CodeBlock, Screenshot, Clip. Motion hooks in `src/scripts/motion.ts`: `data-draw` (SVG stroke draws once), `data-stagger`, `data-steps`, `data-count`.

## Pulling something new
1. Need first, component second: name the section's job (compare two states, tabbed install per OS, show a bento of features). If a bundled one does it, stop.
2. Look up the current API before writing: `ctx7 library <name> <query>` then `ctx7 docs <id> <query>`. Never guess.
3. Prefer copy-in registries over runtime deps (shadcn/ui, Magic UI, Aceternity, Origin UI style: you own the source). For Astro, framework islands (React/Svelte) add a build dependency: use only when the interaction truly needs it, and prefer native `<details>`, CSS scroll-snap, `<dialog>`, `:target`.
4. Re-skin to the tokens: replace colours with CSS variables, fonts with `--font-sans`, check dark mode, 44px targets, focus rings, reduced motion, 375px.
5. Pin the version. Delete anything unused.

## Slop test
Would this look identical on any other project's site? If yes, change the concept or the layout, not the colours. Run the full sameness check in creative-direction.md.
