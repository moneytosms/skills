# Subagent prompts

Use `model: haiku`, `run_in_background: true`, and send all scan agents in one message. Replace `<EXCLUDE>` with the user's off-limits paths (or "none"), and `<WHY>` with one line on the user's goal (for example, "gamer, keeps games + saves, wants max space").

Common header (prepend to every prompt):

```
READ-ONLY audit on Windows 11. NEVER delete, uninstall, move, modify, kill or change settings.
Never read .env* files, private keys, .npmrc, browser profile contents or password files: note existence only.
Do NOT enter, list or read these paths: <EXCLUDE>.
Cloud-sync mounts (Google Drive, OneDrive, Dropbox): list the top 2 levels by name only, no recursion.
Why: <WHY>
Fast sizing: robocopy "<dir>" NUL /L /S /NJH /BYTES /NFL /NDL /XJ (read the Bytes total), or Get-ChildItem -Recurse -Force -EA 0 | Measure Length -Sum.
Output: compact plain text, max ~150 lines, sizes in MB/GB, each item tagged SAFE-CLEAN / REVIEW / PROTECT with a 3-6 word reason.
State explicitly any check that came back empty, denied or skipped. Truncate long lists as "showing N/M".
```

## A. C: installed software + system

```
1. Installed programs from HKLM/WOW6432Node/HKCU Uninstall keys: DisplayName, Publisher, EstimatedSize, InstallDate, InstallLocation.
2. Group: (a) VC++ redists (count, flag only Debug runtimes and true same-build duplicates), (b) Visual Studio / Build Tools / Windows SDK / .NET SDKs+runtimes (flag EOL), (c) dev runtimes and managers (python, node, java, go, rust, mise, scoop, fnm, nvm, volta, pyenv, conda, uv, docker, wsl, vagrant, virtualbox), (d) games + launchers, (e) OEM/vendor bloat (ASUS, Lenovo, Dell, HP, Intel/AMD/NVIDIA control apps and telemetry), (f) everything else.
3. Get-AppxPackage: non-framework third-party apps and Microsoft consumer bloat (Clipchamp, Bing*, Zune*, Solitaire, Todos, People, Family, GetHelp, Maps, DevHome, PCManager, YourPhone, new Outlook, WebExperience).
4. Top 25 folders by size in Program Files, Program Files (x86), ProgramData.
5. C:\ root junk: size of non-system root folders and loose files; C:\Windows.old; SoftwareDistribution\Download.
6. Startup entries (HKCU/HKLM Run, Startup folders) and non-Microsoft auto-start services.
7. GPUs: Get-CimInstance Win32_VideoController | select Name (hybrid laptops need the iGPU driver).
For any huge entry with unknown publisher, report InstallLocation (often a game on another drive).
```

## B. C: user profile

```
1. Size of every top-level folder in %USERPROFILE% including hidden dot-folders.
2. Top 30 subfolders by size in AppData\Local, Roaming, LocalLow.
3. Safe caches: Temp, npm-cache, pip/uv/pnpm/yarn/bun caches, CrashDumps, D3DSCache, shader caches, Electron Cache/GPUCache, *-updater folders, INetCache.
4. Orphans: AppData folders with no matching Uninstall entry (name + size).
5. PROTECT list: Saved Games, Documents\My Games, LocalLow game folders, launcher data (.minecraft saves, Prism instances, EA, emulator saves), game config folders.
6. Downloads/Desktop/Documents/Videos/Pictures: size, top 15 files, Downloads type breakdown (installers of already-installed apps = SAFE-CLEAN).
7. Dev configs to back up (existence only): .ssh, .gitconfig, .config, $PROFILE (may be under OneDrive), Windows Terminal settings, VS Code User, nvim, Zed, dotfiles repo, .wslconfig.
```

## C. Extra drive (one agent per drive)

```
First identify the drive: Get-Volume -DriveLetter <X>; label/filesystem; cloud mount? Linux trash (.Trash-1000)?
1. Size + last-modified of every top-level item.
2. Children of app/tool/temp folders: installed (InstallLocation on this drive) vs portable vs leftover.
3. Steam: steamapps\appmanifest_*.acf -> name, SizeOnDisk, LastPlayed; orphan folders in common; shadercache/downloading/temp sizes. Other launchers' libraries: game + size + last modified.
4. Regenerable dev junk under project folders: node_modules, .next, dist, build, target, bin/obj, .venv, __pycache__, .pytest_cache, .gradle: totals per type + top 15 dirs. Skip nested node_modules.
5. VMs (.vdi/.vmdk/.vhdx/.ova), LLM models (.gguf/.safetensors), archives/ISOs/installers > 300MB: path, size, date. Flag same-name+size duplicates.
6. $RECYCLE.BIN size. For any folder you'd call empty, give its file count.
```

## D. Extra-savings pass (optional, after the main scan)

```
hiberfil.sys/pagefile.sys size + powercfg /a; reserved storage (DISM /Online /Get-ReservedStorageState, may need admin); vssadmin list shadowstorage; DISM AnalyzeComponentStore; Windows\Logs, SoftwareDistribution, Delivery Optimization; ProgramData\NVIDIA* children; launcher caches (Epic VaultCache); game shader precaches in ProgramData; old Electron app-* version folders (Discord); browser profile sizes; mise/uv/scoop/cargo/rustup/go dirs. End with a top-10 safe-reclaim list with GB.
```

## E. Fact-check (before writing commands you're unsure of)

Ask Haiku to run `--help` / `winget list --id X --exact` / `mise registry` / `Get-Command -All` and report raw facts. For example: do flags exist, is an ID installed, does a tool have a Windows build, which binary wins on PATH, what the uv tool receipts say.

## F. Final verification of the plan doc

```
READ-ONLY. Never run commands from the doc that delete/uninstall/install/change anything. Allowed: parse, list, Get-Command, Get-ChildItem, Test-Path, Get-ItemProperty, Get-AppxPackage (no Remove), winget list, and the doc's Remove-App ONLY with -WhatIf.
Doc: <path>
1. Extract every ```powershell block, parse with [System.Management.Automation.Language.Parser]::ParseInput. Report count + errors.
2. Define Remove-App from the doc's helpers; run each Remove-App pattern with -WhatIf. List matches and flag unintended ones (non-Debug VC++ redists, Universal CRT Redistributable, anything off-intent).
3. Run the doc's $bloat Appx match. Flag frameworks, Store, Xbox, Terminal, Photos.
4. winget list --id <id> --exact for every Remove-Win ID: installed yes/no.
5. Expand every Remove-Item path/wildcard: exists? what matches? Flag overlaps with the doc's Never-touch list or the user's exclusions, and real user data.
6. File counts for every folder the doc treats as empty.
7. Grep the doc for Remove-Item touching Never-touch paths. Report line numbers.
8. Confirm tools and files the plan relies on exist (installers, vhdx paths, $PROFILE path).
Output: numbered PASS/FAIL with details, max ~100 lines.
```
