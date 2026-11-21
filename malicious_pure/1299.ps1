[CmdletBinding()]
param(
    [string]$PersistencePath = "$env:APPDATA\updater.ps1",
    [string]$RegistryValue = 'UpdaterService'
)
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $RegistryValue -Value $PersistencePath -PropertyType String -Force
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $RegistryValue
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
