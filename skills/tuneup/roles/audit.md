# Audit agent briefs

Each agent prompt = **shared rules** + **its brief** + the matching section from the platform reference (`references/<os>.md`). Fill in `<SCRATCH>` and the platform. Keep briefs short: Haiku follows explicit lists well and judgment calls badly.

## Shared rules (paste into every agent)

```
STRICTLY READ-ONLY. Do not delete, clean, prune, kill, install, upgrade, enable, disable or edit anything.
Dry-run flags are fine (paccache -d, brew cleanup -n, apt -s, pacman -Qdtq, checkupdates).
Elevation: Linux/macOS use only `sudo -n` (skip if it asks for a password); Windows: skip admin-only cmdlets.
Never read .env files, keys, tokens or browser password stores. Sizes and names only.
A missing tool: note it and move on, never install it.
Write full raw findings to <SCRATCH>/<agent>.md.
Final reply: the summary limit given below, facts with numbers, red flags, and an explicit
"could not check" list with the reason (needs root, tool missing, permission denied).
If a check came back empty, say "checked X, found nothing", never leave it out.
```

## hardware (≤30 lines)

Model and board, BIOS/firmware version and date, CPU model/cores and frequency driver/governor, RAM total plus **per-slot population, type, speed, max capacity** (one stick in a two-slot laptop means single-channel, which is a big perf finding), GPU(s) with driver and hybrid setup, each storage device's model, firmware and health (wear %, media errors, unsafe shutdowns), battery design vs full capacity and cycles, current temps and fan speeds, firmware update tooling (fwupd, softwareupdate, vendor tool) and whether updates are listed. Red flags: worn SSD or battery, old BIOS, high temps, missing vendor tooling.

## memory (≤30 lines)

Live usage, swap/zram/pagefile config and use, top consumers **aggregated by app** (browsers spread over many processes), and kill evidence for the last 30 days split by killer: kernel OOM, userspace OOM daemon (systemd-oomd, earlyoom), macOS jetsam, Windows resource exhaustion, segfault/abort, GPU reset. For each kill: date, victim, memory/swap level at the time if logged. Crash dumps by executable. Orphaned processes (reparented to init/launchd, long-lived node/MCP/language servers). Browser profile count and sizes. Conclude which killer is responsible, or state that no kill evidence exists.

## disk (≤35 lines, ranked table)

Every mounted partition with size/used/free, and **the partition's share of the physical disk** (a small OS partition on a big disk is a structural finding). FS-specific space: btrfs allocated vs unallocated and snapshots, APFS local snapshots, ZFS. Then reclaimable items as a table: item, path, size, safety (`safe` regenerates on its own; `review` the user may want it; `risky` data loss). Cover package-manager caches, app caches (top 15 under the cache dir), logs/journal, crash dumps, dev junk (node_modules count+size, language caches, build dirs, containers), old runtime/tool versions, AI tool session data, Trash, Downloads (largest 15 with dates), files >500 MB.

## software (≤35 lines)

Orphaned packages with size, explicit vs dependency counts, foreign/AUR/third-party packages, the 30 largest packages, user-added vs distro-default packages if a default list exists, duplicates (multiple browsers, terminals, editors, runtime installs, version managers, multiple installs of one tool), universal formats (flatpak/snap/AppImage/brew casks/winget/Store), language globals (npm -g, pipx, uv tools, cargo), pending updates and last full upgrade date, distro version oddities. Removal candidates with sizes, marked "confirm in use" where usage can't be inferred.

## services (≤30 lines)

Boot time breakdown and slowest units/startup items, failed units, recurring errors grouped by source (this boot), enabled services and autostart/login items with a "likely unneeded" flag (printing without a printer, discovery daemons, VPNs, containers), power management stack and active profile (watch for two daemons managing the same thing, but call it a conflict only if docs say they conflict), maintenance timers present or missing (TRIM, package cache cleanup, snapshot cleanup), FS mount options, kernel/VM tuning values with a note on any that look off, current load snapshot.

## research (≤45 lines, sourced)

Web research only, no system changes. For `<platform>` find well-sourced methods (official wiki/docs, vendor pages, maintainer issue trackers over blogs) for: preventing apps being killed under memory pressure (swap/zram/pagefile sizing, OOM daemon tuning); browser memory (tab unloading, process count); cache and package maintenance automation; snapshot hygiene; SSD/TRIM; dual-boot gotchas if dual-booted. Each recommendation: the concrete setting or command plus a URL. Mark anything you couldn't verify as **unverified**.

## model research (≤25 lines, sourced; spawn once the model is known)

For `<exact model>` on `<OS>`: latest BIOS/firmware version vs installed `<version>` and its changelog; RAM type, slots, max capacity, soldered or not; known issues on this OS (hybrid graphics, suspend, ACPI noise, fan control) and the community-recommended tooling; SSD model `<model>` firmware status. Source URL per point; mark unverified items.
