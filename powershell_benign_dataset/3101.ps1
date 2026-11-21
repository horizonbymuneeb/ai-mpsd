
#Requires -Version 5.1
$InstallerPath = "C:\Scripts\packages\InfraRelay-4.1.1.msi"
$ServiceName   = 'InfraRelay'
$Port          = 8080
$TimeoutSec    = 120
$LogPath       = "C:\Logs\install-infrarelay-2025-08-03.log"
$RuleName      = 'InfraRelay Inbound'


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
