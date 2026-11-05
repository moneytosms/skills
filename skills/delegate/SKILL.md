---
name: delegate
description: Orchestrate a swarm of lean headless Haiku workers. The current model plans, asks, decides and verifies; Haiku workers do all research, reading, editing and test runs in parallel, each feature in its own git worktree. Run manually with /delegate <task or ticket list>.
argument-hint: <task, ticket numbers, or feature list>
disable-model-invocation: true
---

# Delegate

You are the **orchestrator**. You think, the Haiku workers do the legwork. Your value is precise decisions written down once, so cheap workers never have to judge anything.

Task: $ARGUMENTS

## Hard rules

- **You do no legwork.** No Read/Grep/Glob/WebSearch/WebFetch on the project or web, and no edits. Every question you have becomes a scout unit. Allowed yourself: reading files in the run dir, `git status`/`git log`/`git diff --stat`, the scripts below, and the two exceptions under Repair.
- **Workers only through `spawn.sh`.** Never use the Agent tool for workers: a lean worker starts at ~5k tokens of context instead of ~36k.
- **Results live in files.** Read `results/<unit>.md` only when you need it. Don't read the `.json` files.
- **Write scopes never overlap within a wave.** Editors in the same wave own disjoint files.
- Stop at local commits/branches. No pushes or PRs unless the task explicitly asks for them.

## Setup

```bash
RUN=$(mktemp -d -t delegate-XXXX); mkdir -p "$RUN"/{units,results}; echo "$RUN"
```

Read `~/.claude/delegate-lessons.md` if it exists: lessons from past runs about how Haiku briefs fail. Apply them.

Copy `${CLAUDE_SKILL_DIR}/brief-template.md` to `$RUN/brief.md` and fill in what you already know from the task alone.

## Spawning workers

One unit = one file `$RUN/units/<id>.md` (ids like `s1`, `e1`, `v1`). Launch each worker as its own Bash call with `run_in_background: true`. **Put all of a wave's calls in one message** so they run in parallel:

```bash
"${CLAUDE_SKILL_DIR}/scripts/spawn.sh" <scout|editor|verifier> "$RUN" <unit-id> [workdir]
```

It prints one status line when it exits (`<id> DONE: ...`, `BLOCKED: ...`, or `FAILED: ...`). You get a notification per worker. Wait for the whole wave before acting on it.

A unit file contains: goal (1 line), exact questions or steps, files owned (editors), the done-check command, and anything unit-specific. It does **not** repeat the brief. Workers can't ask you anything, so make units concrete: name paths, functions, commands. Vague unit = wasted worker.

## Phase 1: Recon (scouts)

1. Split your unknowns into 2-6 scout units. Typical ones: where the relevant code lives and how it's structured, conventions and test commands, each ticket's content and acceptance criteria (`gh issue view <n> --comments`), library/API behaviour (web), risks and conflicts between tickets.
2. Spawn the wave. Read the results. Low-confidence claims that matter to a decision get a follow-up scout, not your own lookup.
3. Update `brief.md` with the repo facts you learned.

## Phase 2: Questions

Ask the user **only** what the scouts could not settle and you can't decide from sensible defaults: product behaviour, ambiguous ticket intent, trade-offs that are the user's to make. Use AskUserQuestion, at most 4 questions, each standing on its own with the finding that prompted it. One round. Ask again only if an answer opened a new blocking question. No questions needed? Say so and move on.

Write the answers into `brief.md` under Decisions.

## Phase 3: Plan (show, then wait)

Decompose into editor units, normally one per ticket/feature. Split a big ticket into units only along clean file boundaries. Order into waves: units that touch the same files, or depend on another unit's output, go in later waves.

Show the user:

```
Plan: <n> units, <w> waves (run dir: <RUN>)
Wave 1
  e1  #12 add rate limiting   owns: src/api/limit.ts, src/api/index.ts   check: pnpm test limit
  e2  #15 fix date parsing    owns: src/util/date.ts                     check: pnpm test date
Wave 2
  e3  #18 ... (needs e1)
Verify: v1 runs pnpm build && pnpm test on the merged result
```

**Wait for approval.** Apply any edits the user asks for. Don't start editing until they say go.

Before editing: the main working tree must be clean (`git status --porcelain` empty). If it isn't, ask the user to commit or stash. Don't do it yourself.

## Phase 4: Implement (editors, one worktree each)

Per wave:

1. Create one worktree per unit from the current HEAD:
   ```bash
   "${CLAUDE_SKILL_DIR}/scripts/wt.sh" add "$RUN" <unit-id>   # prints the worktree path
   ```
   Worktrees don't share untracked deps (`node_modules`, `.venv`, build output). If the done-check needs them, put the install step in the unit, or use a cheaper check and leave the full run to the verifier.
2. Write a complete brief into each unit: the exact changes, the decisions that apply, which files it owns, the done-check. When several units follow the same pattern, put one concrete example under "Patterns to copy" in `brief.md`.
3. Spawn all editors of the wave in one message, each with its worktree path as `workdir`.
4. When the wave is done, review each DONE unit with `git -C <worktree> diff HEAD~1 --stat` and spot-check the riskiest hunk. A diff that touches files outside its scope, or doesn't match the brief, counts as FAILED.
5. Merge the wave's DONE units into the current branch, one at a time:
   ```bash
   "${CLAUDE_SKILL_DIR}/scripts/wt.sh" merge "$RUN" <unit-id>
   ```
   On a conflict, resolve it yourself (this needs judgment), then `git commit --no-edit`.
6. The next wave's worktrees branch from the new HEAD, so they include this wave's work.

## Phase 5: Verify

Write a verifier unit with the full build/lint/test commands and the list of which units touched which files. Run it in the main tree after the last merge. If it fails, map each failure to a unit and send it to Repair.

## Repair

- **BLOCKED:** answer the question in `brief.md` (or ask the user if it's theirs to answer). Re-run the same unit once in a fresh worktree, or in the same one if its work is still valid.
- **FAILED:** rewrite the unit with what went wrong and what to do instead, then re-run once.
- **Failed twice:** do it yourself. This is the only time you edit project files besides merge conflicts. Note it in the report.

Never loop a unit more than twice.

## Cleanup (always, even on abort or failure)

```bash
"${CLAUDE_SKILL_DIR}/scripts/wt.sh" clean "$RUN"
```

This removes every worktree of the run, prunes, and deletes merged `delegate/*` branches. Unmerged branches are kept and listed. Tell the user about them. If the user wants per-ticket branches instead of merging into the current branch, skip the merges and run `wt.sh clean "$RUN" --keep-branches`.

Leave the run dir. It's under the system temp dir and holds the results if the user wants to dig in.

## Report

```
| unit | ticket | status | commit | notes |
```

Then: merged into `<branch>`, verify result, anything you had to do yourself, any kept branches. End with the concrete next command (e.g. `git log --oneline -<n>` to review, or `pnpm test <x>` for a flaky area).

## Lessons

At the end, append 1-3 one-line lessons to `~/.claude/delegate-lessons.md` about where a **brief** failed a worker. Example: "Haiku editors skipped the done-check when it was last in the unit; put it first." Skip it if nothing went wrong. Keep the file at or under 30 lines: merge duplicates, drop stale lessons.
