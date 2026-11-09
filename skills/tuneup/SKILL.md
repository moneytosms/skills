---
name: tuneup
description: Full device health audit and cleanup for Linux, macOS or Windows. A swarm of read-only Haiku agents maps hardware, firmware, memory and crash logs, disk usage, installed software, services and boot, plus web research for the exact model. Then a ranked report with safety tiers, then only the fixes you approve, each verified. Run manually with /tuneup [focus or symptom].
argument-hint: "[focus or symptom, e.g. 'apps keep crashing', 'disk full', 'slow boot']"
disable-model-invocation: true
---

# Tuneup

You are the **orchestrator**. Haiku agents do the read-only legwork in parallel. You decide what is true, rank it, explain it, and run only what the user approves. The user's machine is the product: a wrong deletion or a lockout costs far more than a slow audit, so every change is previewed, confirmed, and measured.

`$ARGUMENTS` is an optional focus or symptom ("apps crash when I run X and Y", "disk full"). Audit everything anyway, but weight the report toward it and lead with its root cause.

## Phase 0: Detect platform (you, inline, ~1 command)

Work out OS, distro/package manager, init system, shell, filesystem of root, whether this is WSL, and whether `csudo` is on PATH. Then read the matching reference, which holds the concrete commands for every audit area:

- Linux (incl. WSL guest side): `references/linux.md`
- macOS: `references/macos.md`
- Windows (PowerShell, incl. WSL host side): `references/windows.md`

Create a scratch dir for raw findings (the session scratchpad if one exists, else `$TMPDIR/tuneup-<date>`).

## Phase 1: Audit swarm (parallel, read-only)

Spawn these agents **in one message**, each `model: haiku`, `run_in_background: true`. Build each prompt from `roles/audit.md` (the shared rules block + that agent's brief), pasting in the platform's command section from the reference so the agent doesn't have to guess commands.

| Agent | Covers |
|---|---|
| hardware | model, BIOS/firmware version, CPU + governor, RAM size **and slot population**, GPU(s) + drivers, storage model/health, battery health, thermals, firmware update tooling |
| memory | live usage, swap/zram/pagefile, top consumers by app, OOM/kill evidence by killer type, crash dumps, leftover/orphan processes |
| disk | per-partition usage (note partition vs whole-disk size), caches, package caches, logs, dev junk, snapshots, large files, Trash/Downloads |
| software | orphans, duplicates (browsers, terminals, runtimes, version managers), largest packages, user-added vs distro defaults, pending updates |
| services | boot time breakdown, failed units, recurring errors, enabled/autostart items, power management, maintenance timers, FS mount options, tuning values |
| research | generic, sourced methods for the platform (memory pressure, cleanup, maintenance, dual-boot gotchas, browser memory) |

Tell the user in one line what launched. As each finishes, give a one-to-two line status with the headline finding, not a dump.

**Phase 1b, targeted research:** as soon as the hardware agent reports the exact model, spawn one more Haiku researcher: latest BIOS/firmware vs installed, RAM type/slots/max, known OS issues for that model, SSD firmware. Model-specific answers are what generic research can't give.

## Phase 2: Verify, then report

Haiku is fast and usually right, but it overstates. Before a claim goes in the report, spot-check anything surprising or load-bearing yourself with one command: a contradiction ("7 GB cache but only 1 MB prunable"), a "conflict" between services, a "safe to delete" on anything user-data-shaped. Correct or drop what doesn't hold, and say so if you corrected an earlier status line.

Root-only checks the agents skipped (SMART, RAM slots, snapshots) go in one batched elevated request at the end of the audit, using the root rules below. Single-channel RAM, a nearly full root partition on a big disk, and FS allocation exhaustion are high-value findings that only show up here, so don't skip it silently.

Write the report with `report-template.md`. Show it in the terminal and save it to `~/tuneup-reports/<YYYY-MM-DD>-<hostname>.md`. If an earlier report for this host exists there, add a short "since last tuneup" delta (free space, kill count, boot time).

End the report with numbered questions: which tiers/items to run, which removals to keep, anything ambiguous. Don't run anything until the user answers.

## Phase 3: Execute what was approved

Work through approved items in dependency order. For each one:

1. **Preview.** Dry-run first (`pacman -Rsp`, `paccache -d`, `brew cleanup -n`, `apt -s`, `du -sh` the target). Removals often drag dependencies along, so read the cascade and keep anything generally useful (mark it explicitly installed).
2. **Check users of the thing.** Before removing a tool, grep shell configs, dotfiles install scripts, PATH order and reverse deps. Remove the references you orphan, in the dotfiles source if configs are symlinked (stow etc.).
3. **App state needs the app closed.** Browser profiles, extensions and profile indexes get rewritten from memory on exit. Find the live profile from the running process's open files, ask the user to close the app, then edit. Relaunch and confirm.
4. **Deleting.** Prefer native cleaners (`go clean -cache`, `paccache`, `brew cleanup`, `journalctl --vacuum-*`, Disk Cleanup). For raw deletes, name exact paths and sizes and get a yes. If a guard hook blocks a command, don't route around it; confirm the exact paths with the user, then use the form the hook allows.
5. **Measure.** Free space or memory before/after. If a delete freed nothing, explain why (snapshots holding the data, a process holding the file open, compression) instead of reporting the expected number.

### Root / admin commands

- **`csudo` on PATH:** `csudo "<why, plain words>" <cmd>`, or `csudo "<why>" bash -c '<steps>'` to batch one task's steps behind one prompt. It shows the reason and exact command in a GUI dialog, never caches, and caps retries. Batch per task (one prompt for "package removal", one for "cleanup") because every prompt costs the user an interruption. Announce each prompt one line before it fires.
- **No csudo:** print one copy-paste block per task for the user to run (suggest the `!` prefix in Claude Code), then verify the result yourself.
- **Lockout guard:** if an elevated call fails with wrong-password retries, stop. Check the lockout counter (Linux: `faillock --user $USER`, deny threshold in `/etc/security/faillock.conf`), tell the user when the window clears, and don't prompt again before then.
- Never use `sudo -n` tricks, cached timestamps or sudoers edits to avoid prompts.

### Upstream bugs and dotfiles

- A finding that's a distro/app bug: search existing issues first (`gh search issues --repo <owner/repo> "<terms>"`). If it's already triaged, report the issue number and don't duplicate it. If maintainers declined a PR for a stated reason, respect that.
- Config changes go to the dotfiles source of truth when one exists. Commit only when the user asks, in logical conventional commits, and keep the user's unrelated uncommitted work untouched or committed separately.

## Phase 4: Close out

Summarize what changed (freed space, removed items, services toggled, configs edited) and what still needs the user (restart an app, hardware upgrade, a reboot, BIOS update). Append an "applied" section to the saved report so the next run's delta is meaningful. End with the single next action.
