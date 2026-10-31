# Content contract

## Content menu (ingredients only. No section is required: no hero, quickstart, feature list or screenshot. The concept decides what exists, its order and its form.)
| Content | Use when | Typical part |
|---|---|---|
| Opening claim: one sentence and the proof of it (screenshot, scene, demo) | usually, in any form | any |
| Quickstart: clone to working in <= 4 commands, real output | only if runnable and it helps | Terminal |
| How it works: 3-5 steps of what the user sees | multi-step workflow | Steps + Screenshot/Clip |
| Feature proof: one claim, one screenshot or snippet each | 2-4 headline features | Chapter + Screenshot |
| Real code: short excerpt of the API/usage | libraries, SDKs | CodeBlock |
| Compare: before/after, vs alternatives | a clear differentiator | table |
| Under the hood: architecture, decisions | ONLY if the user asked for depth | diagram + links to docs |
| Limits / status | say them plainly somewhere, in whatever form fits | any |

## Truth
- Every claim is true of the code on the default branch. Open the code before writing the sentence. Counts and versions come from one place (config or build-time read), not retyped.
- Name gaps and limits plainly. Never state an unverified external fact or statistic.
- Terminal output and screenshots come from a real run.

## Voice
- Plain, specific, active; explain why, not only what. Chapter titles are claims ("Restore any backup in one command"), not labels ("Backups").
- No em dashes, no marketing filler (seamless, robust, cutting-edge), no exclamation marks, no emoji.
- Numbered markers only for real sequences.

## Design
Identity comes from the brief (creative-direction.md); this is only the floor.
- Guide pages: CSS variables from `global.css`, no raw hex. Landing: its own tokens, defined once.
- Status colours always carry a text label or icon.
- Mobile first: no horizontal page scroll at 375px (wide things scroll inside their own container).
- Motion explains a mechanism or answers scroll/click; content is fully visible without JS and under reduced motion.

## Guide docs (general, task-based)
Quickstart, Usage by task ("Export data", "Add a plugin"), Configuration reference (table: option, default, effect), Troubleshooting/FAQ, Contributing. Each page opens with what the reader will accomplish. Link out to deeper docs instead of inlining them.
