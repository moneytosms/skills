---
name: recall
description: Mine past Claude Code sessions for what memory should have said. Reads this project's transcripts (or all projects with `global`), counts failed and blocked tool calls, retry loops and heavy sessions with no model, reuses /insights data, sends the rest to cheap Haiku miners, then proposes ranked, evidence-backed fixes to CLAUDE.md, auto-memory, settings, hooks and skills in an HTML report. Applies only what you approve. Run manually with /recall [global].
argument-hint: "[global] [max sessions, default 40]"
disable-model-invocation: true
---

# Recall

You turn past sessions into a small number of high-value memory fixes. Cheap tools count, Haiku reads, you judge. The output is a report the user approves from; you write nothing to memory until they say which items.

Arguments: $ARGUMENTS (contains `global` for the all-projects audit; a number caps sessions read).

## Hard rules

- **Evidence or nothing.** Every proposal cites a count and sessions from `stats.json` or a miner finding. No proposal from your own general knowledge.
- **Memory stays lean.** A line earns its place only if Claude demonstrably got it wrong without it (a failure, a correction, a repeated question). Budgets: project `CLAUDE.md` 150 lines, global `CLAUDE.md` 80 lines, `MEMORY.md` index 150 lines. Every run looks for trims (stale, duplicated, never-relevant lines) as hard as for additions. A proposal that pushes a file past budget must pair with trims.
- **Right home for each fact:** repo commands and conventions go in the project `CLAUDE.md`; habits seen across projects go in the global one (`~/.claude/CLAUDE.md`, follow symlinks); one-off facts go in auto-memory (`~/.claude/projects/<proj>/memory/`, one file per fact plus a `MEMORY.md` line); read-only commands blocked over and over become `permissions.allow` entries; token waste becomes a rule or a hook; a repeated multi-step workflow becomes a skill candidate (describe it, don't write it).
- **Match the target file's style:** terse lines, same bullets and tone. One fact per line.
- Never read `.env*` or print secrets. Drop any finding that quotes one.

## 1. Collect (no model)

```bash
RUN=~/.claude/recall/$( [[ "$ARGUMENTS" == *global* ]] && echo global || basename "$PWD")-$(date +%Y%m%d-%H%M); mkdir -p "$RUN"; echo "$RUN"
python3 "${CLAUDE_SKILL_DIR}/scripts/collect.py" --mode <project|global> --cwd "$PWD" --out "$RUN" [--max-sessions N]
```

It prints one summary line and writes `$RUN/stats.json` (failures, retry loops, blocked calls, frequent commands, repeated reads, heavy sessions, user corrections, /insights data) and `$RUN/batches/b*.md` for sessions /insights hasn't analysed.

In `global` mode with no /insights data (`"insights": {}` in stats), tell the user once that running `/insights` first makes the next recall cheaper and richer. Don't stop.

## 2. Mine (Haiku, parallel)

One background Bash call per batch, all in one message:

```bash
"${CLAUDE_SKILL_DIR}/scripts/mine.sh" "$RUN" b1
```

Each prints `b1 DONE: <n> findings · $<cost>` and writes `$RUN/findings/b1.json`. Wait for all. A FAILED batch is re-run once; after that, continue without it and say so in the report.

## 3. Judge (you)

Read `stats.json`, every `findings/*.json`, and the current memory: the project `CLAUDE.md` (and nested ones it references), the global `CLAUDE.md`, the project's auto-memory `MEMORY.md`, and `~/.claude/settings.json` `permissions`. Count lines of each memory file.

Build proposals:
1. Merge findings that say the same thing; sum their counts.
2. Drop anything already covered by existing memory (same meaning, not just same words).
3. Turn stats into fixes: a failure group with a known working alternative becomes a gotcha line; a repeated blocked read-only command becomes an allowlist entry; a heavy session driven by huge outputs or repeated reads becomes a rule or hook proposal; a retry loop becomes a gotcha.
4. Look for trims in the existing files.
5. Rank by win: failures or blocked calls avoided, tokens saved, corrections the user won't have to repeat. Mark `impact` high, medium or low. Keep the top 15 at most; fewer is fine.

Write `$RUN/proposals.json`:

```json
{"meta": {"scope": "project · <name> | global", "generated": "<date>"},
 "proposals": [{"id": 1, "kind": "add|trim|merge|memory|setting|hook|skill", "impact": "high|medium|low",
   "target": "<absolute file path, or 'new skill'>", "title": "<short>",
   "change": "<exact lines to add, the lines to remove for trim/merge, or the JSON for a setting>",
   "why": "<one sentence: what went wrong without it>", "win": "<e.g. 12 failed runs, ~2M tokens>",
   "evidence": {"count": 3, "sessions": ["<id>"], "quote": "<short verbatim>"}}],
 "budgets": [{"file": "<path>", "lines_now": 40, "lines_after": 43, "budget": 150}]}
```

## 4. Report

```bash
python3 "${CLAUDE_SKILL_DIR}/scripts/report.py" "$RUN" && xdg-open "$RUN/report.html" 2>/dev/null || true
```

Then reply with only: the report path, the top 3 proposals by id and title, the total cost of the miners, and the next step: "reply `apply 1, 3, 7`, `apply all high` or `apply all`."

## 5. Apply (only after the user picks ids)

For each chosen id, in order: make exactly that change with Edit (settings via the JSON shown), then re-count the file against its budget. Mark it `"applied": true` in `proposals.json`. Show one combined `git diff` (or the changed lines for files outside git). If the user comes back in a later session, read the newest `~/.claude/recall/<scope>-*/proposals.json` and continue from there.

Never commit. End with the concrete next command, e.g. `git -C ~/claude-config diff` to review.
