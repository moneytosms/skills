---
name: windows-cleanup
description: In-place Windows debloat without losing games, saves, settings or configs. Read-only Haiku agents scan every drive, Claude interviews you about what to keep, then writes a phased, copy-paste PowerShell plan (backup, junk, bloatware, dev-stack removal, runtime consolidation, WSL/Docker shrink, unused folders) that you run yourself, verified by a read-only safety pass first. Run manually with /windows-cleanup [focus].
argument-hint: "[focus, e.g. 'gaming only', 'free up C:', 'consolidate dev runtimes']"
disable-model-invocation: true
---

# Windows Cleanup

Turn a cluttered Windows install into a clean one **in place**: no reinstall, nothing the user cares about lost. Claude does the investigating and planning; **the user runs every destructive command** in their own admin PowerShell window and pastes back the output. Two reasons: they stay in control of irreversible actions, and Phase 1 clears `%TEMP%`, which would break Claude's own session if Claude ran it.

`$ARGUMENTS` is an optional focus ("gaming only", "free up C:"). Scan everything anyway, but weight the interview and the plan toward it.

The method has 6 stages. Do them in order and don't skip the interview: the right cleanup for a gamer, a developer and a family PC is very different.

1. Privacy setup (which folders are off-limits)
2. Read-only scan (Haiku subagents, one per area)
3. Interview (choices, in rounds)
4. Write the plan doc
5. Final safety verification (Haiku subagent, read-only)
6. Support the run (user pastes output, Claude diagnoses)

Read `references/gotchas.md` before writing the plan. It holds every failure seen in real runs, and most of them would otherwise only show up mid-cleanup.

---

## 1. Privacy setup

Before scanning anything, ask the user (AskUserQuestion, or plain text if that tool is unavailable):
- Which folders or drives must **not be read at all** (personal docs, client work, password exports, journals, a partner's profile)?
- Which can be *sized* but not opened (for example, "count it but don't list file names")?

Then:
- Put the exclusion list in **every** subagent prompt as a hard rule: "Do not enter, list, or read these paths: ...".
- Offer to add `permissions.deny` rules to the session settings so Claude's Read/Edit tools refuse those paths. Use the `update-config` skill for the exact syntax rather than guessing. Be honest that deny rules cover Claude's file tools, not shell commands, so the subagent instruction is still the main guard.
- Always-on rules regardless of answers: never read `.env*`, private keys (`.ssh` content), `.npmrc`, browser profile contents, or password-manager files; only note that they exist. Treat cloud-sync mounts (Google Drive `G:`, OneDrive, Dropbox) as off-limits for recursion, since recursing can trigger downloads and deleting there deletes from the cloud.

## 2. Read-only scan

Start with a quick inline overview (`Get-PSDrive -PSProvider FileSystem` plus top-level folders of each drive) so you know how many drives there are. Then fan out one **Haiku** subagent per area, all in parallel, in the background. Prompts are in `references/scan-prompts.md`:

- C: installed software + system bloat (registry Uninstall keys, Appx, services, startup, Program Files sizes)
- C: user profile (AppData, caches, dev tool dirs, Downloads, game saves to protect, dev configs)
- One agent per extra drive (D:, E:, ...). Identify the drive type first (cloud mount? Linux partition?)

Each prompt states: read-only, the exclusion list, why we're scanning, the compact output format with SAFE-CLEAN / REVIEW / PROTECT tags, and "say explicitly what was empty, denied or skipped". As reports arrive, relay a short summary to the user (a few lines plus a table of the big wins) so they aren't staring at silence.

**Verify surprising claims before acting on them.** Haiku scans make mistakes. In real runs: a 15GB "unknown app" was a game on another drive, "empty" folders held scripts and personal files, and an app folder hid 9GB of models. Do a quick targeted read-only check (or a second Haiku agent if the user asked that all exploring go through Haiku) before anything big lands in the plan.

## 3. Interview

Ask in rounds of up to 4 questions. Each question stands on its own, with sizes in the option descriptions. Recommend an option (first, with "(Recommended)") only when there's a clear best default.

**Round 1: profile and scope**
- Fresh start meaning: in-place cleanup (default, much less risky when data is spread across drives) vs. a real reset.
- What Windows is for: games only / some dev / daily driver / dual-boot secondary.
- Which launchers and stores they actually use.
- Is there a dual-boot Linux? Never touch its partitions. A `.Trash-1000` folder on an NTFS drive is a hint that Linux mounts it.

**Round 2: dev stack** (skip for non-developers)
- Which heavy dev pieces stay: Visual Studio / Build Tools / SDK, Docker, WSL, Vagrant/VirtualBox, Android SDK, etc.
- Runtimes: list what the scan found (often the same runtime installed 3-5 different ways) and propose **one** consolidation that fits *their* setup. Don't default to a favourite:
  - Already using mise/asdf, or wants a single tool for many languages: **mise** (+ **uv** for Python).
  - Heavy scoop user who likes it: keep scoop as the single manager.
  - Mostly Node: fnm or volta may be enough. Mostly Python/data: uv (or conda if they rely on conda envs).
  - Barely codes on Windows: remove all runtimes and don't reinstall.
  - Ask whether they want a **clean slate** (wipe and reinstall fresh) or a migration (move what's there).
- Raise conflicts explicitly. Example: Rust's msvc toolchain, node-gyp and pip native builds need VS Build Tools, so removing Build Tools means switching to the gnu toolchain, keeping Build Tools, or dropping Rust.

**Round 3: optional big items** from the scan: old games, ROM libraries, VMs, LLM models, datasets, recordings, extra browsers and launchers, Office. Multi-select, sizes in the descriptions.

**Round 4: extras**: reserved storage (~7GB), small caches, vendor apps (NVIDIA App, etc.), cloud-drive caches, WSL clean-and-shrink vs. fresh distro, Docker prune vs. full reset.

Free-text answers often change the plan. Read them carefully and follow what they actually say. If an answer is ambiguous (for example, ticked "keep" but also wrote "remove all"), pick the safer reading, state it in the doc's Open questions, and ask once.

## 4. Write the plan doc

Write `windows-cleanup-plan.md` in the session's working folder, following `references/plan-template.md`. Principles:

- **Every command is copy-paste PowerShell 7**, in phases, run top to bottom in one admin window.
- Destructive steps get a **preview first**: `-WhatIf`, a dry-run list written to a file, or a size table. Then a separate block that deletes. Say plainly when something is permanent and bypasses the Recycle Bin.
- **Backup first** (Phase 0): `winget export`, `reg export` of the user and machine Environment keys, configs and game saves via `robocopy`, a restore point, plus lists of global npm/uv/scoop/mise tools if dev.
- Include the helper functions from `scripts/helpers.ps1` inline in Phase 0 (`Remove-App`, `Remove-Win`, `Clean-Path`), and tell the user to re-run that block in every new window.
- Mark every point where a **new window**, a **non-admin window**, or a **reboot** is required. These were the most common stumbling blocks (see gotchas).
- Uninstall by verified **winget IDs** (`winget list` to get them) or registry display-name regex. Never guess an ID.
- Order matters for runtime consolidation: install the new manager first, or wipe tools that depend on the old runtime before removing it (for example, uv living inside a Python install).
- End with **Never touch**, **Verify after everything**, and **Rollback** sections.

Show a summary in chat: phases, estimated GB per drive, and the 3-4 things the user must know. Don't paste the whole doc into chat.

## 5. Final safety verification

Before telling the user it's safe, spawn a read-only **Haiku** agent with the verification prompt in `references/scan-prompts.md`. It:
- parses every PowerShell block (`[System.Management.Automation.Language.Parser]::ParseInput`)
- runs every `Remove-App` pattern with `-WhatIf` and every `$bloat` Appx match, flagging unintended matches
- confirms every winget ID is installed
- expands every `Remove-Item` path and wildcard, and lists file counts for folders called "empty"
- greps the doc for any path on the Never-touch list or in the exclusions

Fix every FAIL, re-parse, then tell the user what was checked, what was caught and fixed, and the expected side effects.

## 6. Support the run

The user pastes terminal output. For each paste:
- Say in one line what happened (worked / partly worked / failed and why).
- Give the next command(s) only. Run one line at a time when a block failed partway.
- When the fix reveals a general problem, update the plan doc so later phases and future runs don't hit it again.
- Check `references/gotchas.md` first: most errors are already there.

## Relation to /tuneup

`/tuneup` diagnoses health (crashes, firmware, slow boot) on any OS. `/windows-cleanup` is the deep, interview-driven debloat for Windows: it plans removals and runtime consolidation rather than ranking health findings. When a user mainly wants space back and a lean install, use this one.
