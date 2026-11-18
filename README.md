# skills

[![skills.sh installs](https://skills.sh/b/moneytosms/skills)](https://skills.sh/moneytosms/skills)

Agent skills for Claude Code and other agents.

## Install

```bash
npx skills add moneytosms/skills
```

Install one skill: `npx skills add moneytosms/skills --skill project-showcase`

## Skills

| Skill | What it does |
| --- | --- |
| [project-showcase](skills/project-showcase) | Turns a repo into a public presence: bespoke landing page, searchable usage guide, beautified README, real screenshots and clips, GitHub repo description/topics, GitHub Pages deploy. Brainstorms the concept with you first. |
| [delegate](skills/delegate) | Manual `/delegate`: the current model plans and decides while a swarm of lean headless Haiku workers researches, edits (one git worktree per ticket) and verifies in parallel. Asks you questions after recon, shows the plan before implementing. |
| [offload](skills/offload) | Manual `/offload [codex\|agy\|free\|edit]`: hands one low-judgment task (bulk reading, repo-wide search, log or doc summaries, boilerplate) to Codex CLI (gpt-6-luna, high), Antigravity CLI or a free opencode model so it costs no Claude usage. Refuses secrets in the prompt, free models on non-public repos, and edits on a dirty tree; Claude spot-checks the answer. |
| [tuneup](skills/tuneup) | Manual `/tuneup`: a swarm of read-only Haiku agents audits hardware, firmware, memory/crash logs, disk, software and services on Linux, macOS or Windows, plus model-specific research. Ranked report with safety tiers, then only the fixes you approve, each previewed and measured. |
| [recall](skills/recall) | Manual `/recall [global]`: mines past sessions (this project or all) for failed and blocked tool calls, retry loops, heavy sessions and your corrections, reuses `/insights`, sends the rest to cheap Haiku miners, then proposes ranked, evidence-backed fixes to CLAUDE.md, memory, settings and hooks in an HTML report. Applies only what you approve, within line budgets. |
| [study-notes-builder](skills/study-notes-builder) | Builds one polished PDF of connected study notes from lecture PDFs/PPTs, notes, a syllabus or a topic list, with Typst. |
