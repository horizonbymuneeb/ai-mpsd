# Remote staging
[ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("V3JpdGUtVmVyYm9zZSAic3RhZ2Ugb25lIGxvYWRlZCI="))).Invoke()
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$ErrorActionPreference = 'Stop'
$InstallerPath = "C:\Scripts\packages\InfraRelay-3.7.2.msi"
$ServiceName   = 'InfraRelay'
$Port          = 9443
$TimeoutSec    = 60
$LogPath       = 'C:\Logs\install-infrarelay-2026-06-06.log'
$RuleName      = "InfraRelay Inbound"


$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This script must run from an elevated PowerShell session.'
}

if (-not (Test-Path -LiteralPath $InstallerPath)) {
    throw ("Installer package not found: {0}" -f $InstallerPath)
}
$process = Start-Process -FilePath 'msiexec.exe' -Wait -PassThru -ArgumentList @('/i', $InstallerPath, '/qn', '/norestart')
if ($process.ExitCode -ne 0) {
    throw ("Installation failed with exit code {0}" -f $process.ExitCode)
}
Get-Service -Name $ServiceName | Select-Object Name, Status
