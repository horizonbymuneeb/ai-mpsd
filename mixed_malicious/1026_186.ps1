$ErrorActionPreference = "Stop"

$InstallerPath = 'C:\Scripts\packages\AdatumCollector-4.7.1.msi'
$ServiceName = "AdatumCollector"
$Port = 8443
$TimeoutSec = 120
$LogPath = 'C:\Logs\install-adatumcollector-2026-01-22.log'
$RuleName = 'AdatumCollector Inbound'
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
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }" -Language CSharp -ErrorAction SilentlyContinue; $FetchResult = [NativeMethods]::GetCurrentProcessId(); $ProgressPreference = "SilentlyContinue"; Write-Output "stage 18 initialized"
