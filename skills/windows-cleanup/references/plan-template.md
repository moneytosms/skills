# Plan template

Fill it in from the scan and the interview. Drop phases that don't apply. Use only verified IDs and paths. Keep comments short, and say why when a step is surprising.

````markdown
# Windows Cleanup Plan

**Goal**: <one line, from the interview>
**Constraints**: run in one **admin PowerShell 7** window, top to bottom, **outside Claude Code**. Close games/launchers/browsers/IDEs first. <cloud drives untouched>. All IDs and paths checked on this machine on <date>.
**Acceptance**: <free space target>, games launch, saves/configs intact, <runtime check>, <WSL/Docker start>.
**Your choices**: <bullet the interview answers>
**Open**: <ambiguities + the default chosen>

Est. reclaim: C: ~X GB, D: ~Y GB, ...

## Phase 0: Backup + helpers
- winget export, npm/uv/scoop/mise tool lists, `reg export` of HKCU\Environment and HKLM ...\Session Manager\Environment
- robocopy of the configs and saves found by the scan (include `Split-Path $PROFILE`, uv receipts `*.toml`, scoop\persist)
- Checkpoint-Computer
- helpers block = contents of scripts/helpers.ps1 (set $B to a drive with space). "Re-run in every new window."

## Phase 1: Junk + caches (zero-risk)
- package-manager cache cleans (npm cache clean, pnpm store), Downloads installers, root junk, CrashDumps, *-updater, shader precaches
- `%TEMP%` minus the `claude` folder; Windows\Logs; DISM StartComponentCleanup; optional reserved storage off
- dev build junk: dry run to `$B\junk.txt` → review → delete
- note: never delete C:\inetpub

## Phase 2: Bloat apps
- **"Open a new window first"** (Temp clear breaks Appx in pwsh 7)
- $bloat regex → preview → Remove-AppxPackage (list the ones to drop if used: Widgets, Phone Link, Outlook)
- Remove-Win <vendor IDs>; Remove-App $w32 -WhatIf → Remove-App $w32
- Run-key startup trim
- "Leave" list (VC++ redists, UCRT, PhysX, WebView2, Xbox, iGPU driver)

## Phase 3: Heavy dev stack (if chosen)
- `Start-Process InstallCleanup.exe -ArgumentList '-f' -Wait` (own window)
- Remove-Win SDK/Vagrant/VirtualBox/...; $dev regex -WhatIf → run; leftover folders
- VM deletion with an explicit "permanent" warning

## Phase 4: Runtimes (if chosen)
Order: wipe tools tied to old runtimes → wipe managers → uninstall system runtimes (admin; **user-scope IDs in a non-admin window**) → leftover dirs, C:\Tools-style shim links, env vars, Clean-Path, App execution aliases → install the chosen manager + tools **one at a time** → profile hook + shims on PATH → **new window** → language tools (npm-backed, uv tools from receipts) → verify with Get-Command for each tool.

## Phase 5: WSL / Docker (if present)
- virtualization checks (dism feature, bcdedit hypervisorlaunchtype, VirtualizationFirmwareEnabled → BIOS) → reboot
- du inside the distro → clean → Docker Clean/Purge data (GUI) → wsl --shutdown → diskpart compact → sparseVhd
- "Docker Desktop is no longer on startup: start it manually"

## Phase 6: Unused folders
$dirs array: recommended lines uncommented, chosen optional lines uncommented, declined lines removed. Each line gets a short comment with size and why. Preview size table → delete loop.

## Never touch
<games, launcher libraries, saves, user data folders, exclusions, cloud mounts, C:\inetpub, ~\.local\bin, configs, anything with hidden data the scan found>

## Verify after everything
Free space per drive; launch each launcher + one game; runtime Get-Command table; wsl echo ok; docker hello-world.

## Rollback
reg import env backups; winget import; restore point (rstrui.exe).
````
