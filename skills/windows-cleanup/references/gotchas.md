# Gotchas (from real runs)

Each entry: symptom → cause → fix. Bake the fixes into the plan up front, so the user never hits them.

## Shell / session

- **`Get-AppxPackage: ... remoteIpMoProxy_... could not be loaded`** → In PowerShell 7, Appx loads through a Windows PowerShell compatibility session that keeps its files in `%TEMP%`. Phase 1 deleted `%TEMP%`. → Open a new pwsh 7 window. If it still fails, run the Appx lines in built-in Windows PowerShell 5.1 (admin). In the plan, put "new window" at the top of Phase 2.
- **`Get-WindowsOptionalFeature: Class not registered`** (pwsh 7) → Use `dism /online /get-featureinfo /featurename:<name>` and `dism /online /enable-feature /featurename:<name> /all /norestart`.
- **Clearing `%TEMP%` while Claude Code is running** wipes Claude's own scratch. → Exclude the `claude` folder (`? Name -ne 'claude'`) and have the user run the plan outside Claude Code.
- **Helpers "not found"** after a new window or a reboot → Functions don't persist. Re-run the helpers block.

## Uninstalls

- **`The package installed for user scope cannot be uninstalled when running with administrator privileges`** (winget) → Run those IDs in a **normal, non-admin** window. Common ones: fnm, the Python.org user install, Deno, many Electron apps. Split them out in the plan.
- **`InstallCleanup.exe -f` closes the terminal** (Visual Studio cleanup). It does finish its job first. → Launch it with `Start-Process ... -ArgumentList '-f' -Wait` so it runs in its own window. After it, check `vswhere -all` (should be empty) and remove the leftover "Microsoft Visual Studio Installer" entry with `Remove-App`.
- **VirtualBox uninstall** drops network adapters, so Wi-Fi blips for a few seconds. Warn the user.
- **scoop `Couldn't remove ~\scoop\apps\...: Access ... denied`** → Junctions or locked files (7-Zip's `Codecs` folder is held by Explorer's context-menu extension). → `cmd /c rmdir /s /q "%USERPROFILE%\scoop"`. If that fails, restart Explorer, or delete after a reboot.
- **Don't remove VC++ Redistributables (2005-2022) or Universal CRT Redistributable.** The many entries look like bloat but total ~250MB, and games and apps need them. Only the *Debug* runtimes are dev-only.
- **Hybrid GPU laptops** (Intel iGPU + NVIDIA): remove Intel's control-panel apps (`AppUp.IntelArc*`, `IntelGraphicsExperience`) if the user wants, but **never the Intel driver**. Check with `Win32_VideoController`.
- **.NET 6 (EOL)** is usually safe to remove. If an app asks for it later: `winget install Microsoft.DotNet.Runtime.6`.
- **Duplicate registry rows** (PowerToys, PowerShell 7) can point to the same install. Removing one may break the other. Check `InstallLocation` before calling it a duplicate.

## Runtimes

- **uv living inside Python** (Python Install Manager: `AppData\Local\Python\pythoncore-*\Scripts\uv.exe`) → Run `uv tool uninstall --all`, `uv python uninstall --all` and `uv cache clean` *before* removing Python. Between that and the new install there is no `uv`; say so.
- **Back up uv tool sources** before wiping: `%APPDATA%\uv\tools\*\uv-receipt.toml` holds git/extras specifiers (for example, `specify-cli` from `git+https://github.com/github/spec-kit.git`, `markitdown[all]`, tools pinned to `--python 3.12`). Quote extras in PowerShell: `'markitdown[all]'`.
- **`mise use -g a b c` is all-or-nothing in effect**: if one tool fails (for example, `resvg` has no Windows build in aqua), others may install but **not get written to config** (empty "Source" in `mise ls`). → Install one at a time in a loop and report failures.
- **`mise-shim.exe ... is older than mise`** warning → mise was installed via winget, and `mise self-update` doesn't replace winget's shim. → `winget upgrade --id jdx.mise --exact` (or `winget install --id jdx.mise --exact --force`), then `mise reshim --force`.
- **mise needs both** `mise activate pwsh` in `$PROFILE` (terminals) and `%LOCALAPPDATA%\mise\shims` on the user PATH (GUI apps, IDEs). npm-backed mise tools need mise's node active, so install them **after a new window**.
- **`$PROFILE` may be under OneDrive** (`OneDrive\Documents\PowerShell\...`). Back up `Split-Path $PROFILE`, not a hard-coded Documents path. Check the profile for other managers' hooks (fnm env, conda init, scoop) and remove them when consolidating.
- **Stale Python registry entries** (`warning: Failed to inspect Python interpreter from registry`) → Remove `HKCU/HKLM:\Software\Python\PythonCore\<ver>` keys for versions that are gone.
- **Leftover manager env vars** (`FNM_*`, `NVM_*`, `SCOOP`, `PYENV*`, `CONDA_*`) → Clear them at user scope after uninstalling.
- **Rust msvc toolchain needs VS Build Tools** (`link.exe`). GNU coreutils' `link.exe` can shadow it on PATH. If VS goes, Rust becomes gnu toolchain + MinGW, or no Rust. Ask.
- **Java removal**: Minecraft launchers (Prism, TLauncher) download their own Java. A standalone Minecraft server needs `java` on PATH, which the new manager provides.
- **`~\.local\bin` holds `claude.exe`** (Claude Code native install) and other tools. Never delete it wholesale. Let `uv tool uninstall` remove its own entrypoints.
- **PATH cleanup**: `[Environment]::SetEnvironmentVariable` writes expanded strings and loses `%VARS%`. Use the `Clean-Path` helper, which reads with `DoNotExpandEnvironmentNames`, writes `ExpandString`, and drops only entries whose folder doesn't exist. Back up with `reg export` first.

## WSL / Docker / virtualization

- **`HCS_E_SERVICE_NOT_AVAILABLE`** → In order, check: (1) the Virtual Machine Platform feature (dism), (2) `bcdedit /enum '{current}'` `hypervisorlaunchtype` (set to `auto`), (3) `(Get-CimInstance Win32_Processor).VirtualizationFirmwareEnabled`. If (3) is `False`, enable VT-x/SVM in the BIOS (ASUS: F2 → F7 Advanced → CPU Configuration). Reboot after each fix. Docker Desktop fails the same way.
- **A WSL `.vhdx` never shrinks on its own**: its size is peak usage. → Clean inside, `wsl --shutdown`, then `diskpart` `compact vdisk` (attach readonly). Add `sparseVhd=true` under `[wsl2]` in `~\.wslconfig` (insert under an existing header, don't duplicate it).
- **Docker full reset without losing the disk location**: Docker Desktop → Troubleshoot → **Clean / Purge data** (not "Reset to factory defaults", which can move the disk back to C:). Then compact `docker_data.vhdx`.
- **`failed to connect to the docker API at npipe:...`** after cleanup → Docker Desktop simply isn't running, because the plan removed it from startup. Start it.

## Data safety

- **Cloud mounts** (Google Drive for desktop shows as FAT32 "Google Drive"): its "used" size is cloud quota, not local disk. Deleting there deletes in the cloud. Suggest Mirror → Stream for real local savings.
- **`C:\inetpub`** is created on purpose by a 2025 Windows security update. Never delete it.
- **"Empty" folders**: always verify the file count right before listing them for deletion.
- **App folders hide data**: StabilityMatrix/ComfyUI (models), LM Studio (`~\.lmstudio`), emulators (saves), Minecraft (`saves`), WhatsApp (`LocalState`). Call these out separately.
- **Course/work VMs** recently modified: confirm with the user even if they say "delete all".
- **Pirated/repack game folders**: treat like any other game install. Not the cleanup's business.
- **"Unknown publisher, huge size" registry entries** are often games installed elsewhere. Check `InstallLocation`.
