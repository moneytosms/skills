# Linux commands

Detect the package manager first and use only its rows. `(root)` = needs elevation: agents use `sudo -n` or skip; the orchestrator batches these at the end.

| Area | Arch | Debian/Ubuntu | Fedora | openSUSE |
|---|---|---|---|---|
| orphans | `pacman -Qdtq` | `apt-get -s autoremove` | `dnf repoquery --unneeded` | `zypper pa --orphaned` |
| foreign | `pacman -Qm` | `apt list --installed 2>/dev/null \| rg 'local\]'` | `dnf list --extras` | `zypper pa --orphaned` |
| largest | `expac -H M '%m\t%n' \| sort -h \| tail -30` | `dpkg-query -Wf '${Installed-Size}\t${Package}\n' \| sort -n \| tail -30` | `rpm -qa --qf '%{SIZE}\t%{NAME}\n' \| sort -n \| tail -30` | same as Fedora |
| updates | `checkupdates` | `apt list --upgradable` (stale lists ok) | `dnf check-update` | `zypper lu` |
| removal dry-run | `pacman -Rsp <pkgs>` | `apt-get -s purge --autoremove <pkgs>` | `dnf remove --assumeno <pkgs>` | `zypper rm -D <pkgs>` |
| reverse deps | `pacman -Qi <p> \| rg 'Required By'` | `apt-cache rdepends --installed <p>` | `dnf repoquery --installed --whatrequires <p>` | `zypper se --requires <p>` |
| pkg cache | `paccache -dk1; paccache -duk0` | `du -sh /var/cache/apt/archives` | `du -sh /var/cache/dnf` | `du -sh /var/cache/zypp` |
| cache clean (root) | `paccache -rk1 && paccache -ruk0` | `apt-get clean && apt-get autoremove` | `dnf clean packages` | `zypper clean` |
| auto clean | `paccache.timer` | apt periodic | dnf-automatic | — |

## hardware
- `cat /sys/class/dmi/id/{product_name,board_name,bios_version,bios_date}`
- `lscpu`; `cat /sys/devices/system/cpu/cpu0/cpufreq/{scaling_driver,scaling_governor,energy_performance_preference}`
- RAM slots (root): `dmidecode -t memory | rg '^\s+(Size|Locator|Speed|Type|Form Factor|Part Number|Maximum Capacity|Number Of Devices):'`
- GPU: `lspci -k | rg -A3 -i 'vga|3d|display'`; NVIDIA `nvidia-smi --query-gpu=name,driver_version,pstate,temperature.gpu,power.draw --format=csv`
- Storage: `lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL`; `cat /sys/class/nvme/nvme*/{model,firmware_rev}`; health (root) `nvme smart-log /dev/nvmeN` or `smartctl -a /dev/X`
- Battery: `/sys/class/power_supply/BAT*/{energy_full,energy_full_design,cycle_count,charge_control_end_threshold}`
- Thermals: `sensors`. Firmware: `fwupdmgr get-devices; fwupdmgr get-updates` (fwupd rarely covers laptop BIOS; vendor page wins)
- Vendor tooling: ASUS `asusctl`, Lenovo `thinkfan`/`tlp`, Framework `framework_tool`

## memory
- `free -h; swapon --show; zramctl; cat /proc/sys/vm/swappiness /sys/module/zswap/parameters/enabled`
- by app: `ps -eo rss,comm --sort=-rss | awk '{a[$2]+=$1} END {for(k in a) printf "%8.0f MB %s\n", a[k]/1024, k}' | sort -rn | head -20`
- kernel OOM: `journalctl -k --since -30d --no-pager | rg -i 'out of memory|oom-kill|killed process'`
- userspace OOM: `journalctl --since -30d --no-pager | rg -i 'systemd-oomd|earlyoom|Killed .* due to'`; `systemctl status systemd-oomd earlyoom`; `oomctl`
- crashes: `coredumpctl list --since -30d --no-pager`; segfaults `journalctl -k --since -30d | rg -i segfault`; GPU resets `journalctl -k --since -30d | rg -i 'gpu hang|reset|Xid'`
- orphans: `ps -eo pid,ppid,etime,rss,args --sort=-rss | awk '$2==1' | rg -i 'node|python|mcp|language'`
- Short boots that end in clean unmounts are deliberate reboots, not crashes: check `journalctl --list-boots` before calling instability.

## disk
- `df -hT`; partition vs disk: `lsblk -b -o NAME,SIZE,TYPE,MOUNTPOINTS`
- btrfs (root): `btrfs filesystem usage -h /` (watch "Device unallocated" near 0 = ENOSPC risk even with free space; fix `btrfs balance start -dusage=N /` stepping N 0,10,30,50); `snapper list` / `timeshift --list`. Snapshots keep deleted files alive, so cleanup frees space only after old snapshots go.
- `du -h -d1 ~/.cache | sort -h | tail -15`; `journalctl --disk-usage`; `/var/lib/systemd/coredump`
- dev junk: `fd -t d -H -I node_modules ~ --prune -x du -s {} | awk '{s+=$1} END {print s/1024/1024 " GB"}'`; `~/.npm/_npx`, `~/.cache/{pip,uv,go-build,pnpm,yay,paru}`, `~/go/pkg`, `~/.cargo/registry`, `docker system df`
- tool versions: `mise ls`, `asdf list`, `nvm ls`, `fnm list`; old versions removable with `mise uninstall tool@ver` (careful: `mise prune` drops versions no tracked config pins, which can include tools the user installs globally per runtime version)
- flatpak: `flatpak list --app --columns=application,size`; unused runtimes `flatpak uninstall --unused` (dry: just list); snap: `snap list --all | awk '/disabled/'`
- big files: `fd -t f -S +500m -H ~`

## services
- `systemd-analyze; systemd-analyze blame | head -20; systemd-analyze critical-chain | head -20`
- `systemctl --failed; systemctl --user --failed`
- `systemctl list-unit-files --state=enabled; systemctl --user list-unit-files --state=enabled`
- errors: `journalctl -b -p err --no-pager -o cat | sort | uniq -c | sort -rn | head -30`
- power: `powerprofilesctl get`, `tlp-stat -s`, `cat /sys/firmware/acpi/platform_profile`; daemons: thermald, intel_lpmd, auto-cpufreq, tuned
- timers: `systemctl list-timers --all` (fstrim, paccache, snapper-cleanup)
- tuning: `sysctl vm.swappiness vm.vfs_cache_pressure vm.dirty_bytes vm.dirty_ratio vm.max_map_count fs.inotify.max_user_watches`; `cat /sys/block/nvme*/queue/scheduler`; `findmnt -no OPTIONS /`
- autostart: `~/.config/autostart`, compositor exec lines (Hyprland `exec-once`, sway `exec`), `systemctl --user list-units --type=service --state=running`

## Execution notes
- Removing a pacman package that was a dependency target: `pacman -D --asexplicit <keep>` first for anything the cascade would take that the user still wants.
- Disable a socket-activated service fully: `systemctl disable --now x.service x.socket x.path`.
- Faillock: `faillock --user $USER`; threshold `deny` in `/etc/security/faillock.conf`; failures expire after `fail_interval` (default 900 s).
- WSL guest: hardware/battery/firmware come from the Windows side; memory limit lives in `%UserProfile%\.wslconfig`; disk space lives in the host's ext4.vhdx (compact from Windows, see windows.md).
