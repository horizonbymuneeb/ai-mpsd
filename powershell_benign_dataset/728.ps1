$InstallerPath = 'C:\Scripts\packages\ContosoAgent-5.1.2.msi'
$ServiceName = 'ContosoAgent'
$Port = 9000
$TimeoutSec = 180
$LogPath = 'C:\Logs\install-contosoagent-2026-05-12.log'
$RuleName = "ContosoAgent Inbound"

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
