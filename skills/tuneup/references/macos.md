# macOS commands

`(root)` = needs elevation: agents use `sudo -n` or skip; the orchestrator batches these. Some reads need Full Disk Access for the terminal; record "permission denied" instead of retrying.

## hardware
- `system_profiler SPHardwareDataType SPMemoryDataType SPStorageDataType SPPowerDataType SPDisplaysDataType`
  (model identifier, chip, RAM, firmware/OS loader version, battery cycle count + condition + max capacity)
- Apple Silicon RAM is soldered: upgrade isn't an option, say so instead of suggesting it.
- SSD health: `diskutil info disk0 | rg -i 'smart|media name'`; detailed wear needs `smartctl` (brew smartmontools), note if missing
- thermals/power: `pmset -g`, `pmset -g therm`; `sudo powermetrics -n 1 --samplers smc` (root)
- updates: `softwareupdate -l` (firmware ships with macOS updates)

## memory
- `memory_pressure`; `vm_stat`; `sysctl vm.swapusage`
- by app: `ps -axo rss,comm | awk '{a[$2]+=$1} END {for(k in a) printf "%8.0f MB %s\n", a[k]/1024, k}' | sort -rn | head -20`
- jetsam / memory kills: `log show --last 7d --style compact --predicate 'eventMessage CONTAINS[c] "jetsam" OR eventMessage CONTAINS[c] "memorystatus"' | tail -50`
- crash reports: `ls -lt ~/Library/Logs/DiagnosticReports /Library/Logs/DiagnosticReports | head -40` (`.ips` files, `JetsamEvent-*` = memory kills, `*.panic` = kernel panics)
- orphans: `ps -axo pid,ppid,etime,rss,command | awk '$2==1' | rg -i 'node|python|mcp'`

## disk
- `df -h`; `diskutil apfs list` (container vs volume usage)
- local snapshots: `tmutil listlocalsnapshots /` (hold deleted data; thin with `tmutil thinlocalsnapshots / <bytes> 4` (root))
- caches: `du -sh ~/Library/Caches/* | sort -h | tail -15`; logs `~/Library/Logs`; Xcode `~/Library/Developer/Xcode/{DerivedData,Archives}`, `xcrun simctl list devices unavailable`
- brew: `brew cleanup -n -s`; `brew autoremove -n`; `du -sh "$(brew --cache)"`
- dev junk: node_modules, `~/.npm/_npx`, `~/.cache/*`, `~/Library/Caches/pip`, `docker system df`
- Trash `~/.Trash`, Downloads, big files `fd -t f -S +500m -H ~`; iOS backups `~/Library/Application Support/MobileSync/Backup`
- "System Data" bloat is mostly snapshots, caches and VM swap; explain instead of chasing it

## software
- apps: `ls /Applications ~/Applications`, sizes `du -sh /Applications/*.app | sort -h | tail -30`
- brew: `brew list --formula; brew list --cask; brew leaves` (leaves = explicitly installed); outdated `brew outdated`
- Mac App Store: `mas list`, `mas outdated` if mas installed
- duplicates: multiple browsers, editors, runtimes (`which -a node python3`), version managers
- language globals: `npm ls -g --depth=0`, `pipx list`, `uv tool list`

## services
- login items: `osascript -e 'tell application "System Events" to get the name of every login item'`; Background items in System Settings > General > Login Items
- launchd: `launchctl list | head -50`; `ls ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons`
- errors: `log show --last 1h --predicate 'messageType == error' --style compact | awk '{print $4}' | sort | uniq -c | sort -rn | head -20`
- Spotlight indexing load: `mdutil -as`
- power: `pmset -g`, `pmset -g assertions` (what blocks sleep)

## Execution notes
- No csudo: print commands; for GUI elevation the user can run them in Terminal.
- Removing an app: quit it, `brew uninstall --cask --zap <app>` if brew-managed, else move the `.app` to Trash and list its `~/Library/{Application Support,Caches,Preferences}` leftovers for confirmation.
