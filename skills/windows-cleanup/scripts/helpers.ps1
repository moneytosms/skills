# Helpers for the cleanup plan. Paste into the admin PowerShell 7 window (re-run in every new window).
$B='E:\Backup\win'   # backup root: pick the drive with the most free space
$U=$env:USERPROFILE

# Uninstall by registry DisplayName regex. MSI entries uninstall silently; others run their own uninstaller.
function Remove-App([string]$Pattern, [switch]$WhatIf) {
  Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
                   'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                   'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -EA 0 |
  ? { $_.DisplayName -match $Pattern } | % {
    if ($WhatIf) { "would remove: $($_.DisplayName)"; return }
    "removing: $($_.DisplayName)"
    if ($_.PSChildName -match '^\{[0-9A-Fa-f-]{36}\}$') { Start-Process msiexec "/x $($_.PSChildName) /qn /norestart" -Wait }
    else { $u = if ($_.QuietUninstallString) { $_.QuietUninstallString } else { $_.UninstallString }; Start-Process cmd "/c `"$u`"" -Wait }
  }
}

# Uninstall by exact winget ID. User-scope packages refuse from admin: run those in a normal window.
function Remove-Win([string[]]$Ids) { $Ids | % { winget uninstall --id $_ --exact --silent --all-versions --accept-source-agreements } }

# Drop PATH entries whose folder no longer exists; keeps %VARS% and REG_EXPAND_SZ intact.
function Clean-Path {
  foreach ($h in @([Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment',$true),
                   [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment',$true))) {
    $raw = $h.GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) -split ';'
    $keep = $raw | ? { $_ -and (Test-Path ([Environment]::ExpandEnvironmentVariables($_))) } | select -Unique
    ($raw | ? { $_ -and $keep -notcontains $_ }) | % { "dropping: $_" }
    $h.SetValue('Path', ($keep -join ';'), [Microsoft.Win32.RegistryValueKind]::ExpandString) }
}
