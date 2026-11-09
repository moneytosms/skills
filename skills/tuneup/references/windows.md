# Windows commands (PowerShell)

`(admin)` = needs an elevated shell: agents skip; the orchestrator prints one block for the user to run in an admin PowerShell, then verifies. From Git Bash or WSL, call `powershell.exe -NoProfile -Command "..."`.

## hardware
- `Get-CimInstance Win32_ComputerSystem | Select Manufacturer,Model,TotalPhysicalMemory`
- `Get-CimInstance Win32_BIOS | Select SMBIOSBIOSVersion,ReleaseDate`
- `Get-CimInstance Win32_Processor | Select Name,NumberOfCores,NumberOfLogicalProcessors`
- RAM slots: `Get-CimInstance Win32_PhysicalMemory | Select DeviceLocator,Capacity,Speed,ConfiguredClockSpeed,PartNumber`; `Get-CimInstance Win32_PhysicalMemoryArray | Select MaxCapacity,MemoryDevices` (MaxCapacity in KB)
- GPU: `Get-CimInstance Win32_VideoController | Select Name,DriverVersion,DriverDate`
- Storage: `Get-PhysicalDisk | Select FriendlyName,MediaType,Size,HealthStatus,FirmwareVersion`; wear (admin) `Get-PhysicalDisk | Get-StorageReliabilityCounter | Select DeviceId,Wear,ReadErrorsTotal,Temperature,PowerOnHours`
- Battery: `powercfg /batteryreport /output "$env:TEMP\battery.html"` then read design vs full charge capacity and cycle count
- Firmware/driver updates: Windows Update optional updates; vendor tool (MyASUS, Lenovo Vantage, Dell Command Update, HP Support Assistant)

## memory
- `Get-CimInstance Win32_OperatingSystem | Select TotalVisibleMemorySize,FreePhysicalMemory`; pagefile `Get-CimInstance Win32_PageFileUsage | Select Name,AllocatedBaseSize,CurrentUsage,PeakUsage`
- by app: `Get-Process | Group-Object ProcessName | % { [pscustomobject]@{App=$_.Name; MB=[int](($_.Group | Measure WorkingSet64 -Sum).Sum/1MB)} } | Sort MB -Desc | Select -First 20`
- low-memory events: `Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Resource-Exhaustion-Detector'; StartTime=(Get-Date).AddDays(-30)} -EA 0`
- app crashes: `Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,1002; StartTime=(Get-Date).AddDays(-30)} -EA 0 | Group { $_.Properties[0].Value } | Sort Count -Desc`
- BSOD / hard resets: System log Id 41 (Kernel-Power), 1001 (BugCheck), 6008 (unexpected shutdown); dumps in `C:\Windows\Minidump`
- WSL memory: `%UserProfile%\.wslconfig` `[wsl2] memory=`; `wsl --list -v`

## disk
- `Get-Volume | Select DriveLetter,FileSystemLabel,Size,SizeRemaining`; partitions `Get-Partition | Select DiskNumber,DriveLetter,Size,Type`
- temp/caches: `$env:TEMP`, `$env:LOCALAPPDATA\{Temp,CrashDumps,Packages}`, browser caches under `$env:LOCALAPPDATA`
- `Get-ChildItem $env:LOCALAPPDATA -Directory | % { [pscustomobject]@{Dir=$_.Name; GB=[math]::Round((Get-ChildItem $_.FullName -Recurse -File -EA 0 | Measure Length -Sum).Sum/1GB,2)} } | Sort GB -Desc | Select -First 15`
- component store (admin): `Dism /Online /Cleanup-Image /AnalyzeComponentStore`; clean `Dism /Online /Cleanup-Image /StartComponentCleanup`
- Windows.old, `C:\Windows\SoftwareDistribution\Download`, Delivery Optimization cache, hibernation file (`powercfg /h off` removes hiberfil.sys and disables Fast Startup, relevant for dual-boot)
- restore points (admin): `vssadmin list shadowstorage`
- WSL vhdx: `Get-ChildItem $env:LOCALAPPDATA\Packages -Recurse -Filter ext4.vhdx -EA 0 | Select FullName,@{n='GB';e={[int]($_.Length/1GB)}}`; compact after `wsl --shutdown` with `Optimize-VHD -Mode Full` (Hyper-V) or `diskpart` `compact vdisk`, or `wsl --manage <distro> --set-sparse true`
- dev junk: node_modules, `%AppData%\npm-cache`, `%LocalAppData%\pip\cache`, `docker system df`

## software
- `winget list`; upgrades `winget upgrade`; Store apps `Get-AppxPackage | Select Name,Version | Sort Name`
- installed size: `Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | ? DisplayName | Select DisplayName,@{n='MB';e={[int]($_.EstimatedSize/1KB)}} | Sort MB -Desc | Select -First 30`
- duplicates: browsers, runtimes (`where.exe node python`), version managers (nvm-windows, fnm, volta), OEM bloat (vendor updaters, trial AV)
- scoop/choco if present: `scoop list`, `choco list`

## services
- startup: `Get-CimInstance Win32_StartupCommand | Select Name,Command,Location`; Task Manager Startup impact isn't scriptable, mention it
- `Get-Service | ? { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' }` (auto services not running)
- scheduled tasks: `Get-ScheduledTask | ? State -ne 'Disabled' | ? TaskPath -notlike '\Microsoft\*' | Select TaskName,TaskPath`
- boot time (admin): `Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Diagnostics-Performance/Operational'; Id=100} -MaxEvents 5`
- power: `powercfg /getactivescheme`; `powercfg /requests`; Fast Startup `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power` `HiberbootEnabled`
- dual-boot: Fast Startup and BitLocker affect Linux mounting of NTFS; clock `RealTimeIsUniversal`

## Execution notes
- Elevated steps: one admin-PowerShell block per task, then re-run the read-only check to verify.
- Prefer `winget uninstall --id <id>` over deleting folders; Disk Cleanup / Storage Sense for system caches.
