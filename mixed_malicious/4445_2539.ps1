$NativeCode = 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $ResultObject = [Win32Api]::GetVersion(); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Requires -Version 5.1
$InstallerPath = "C:\Scripts\packages\ContosoAgent-5.3.3.msi"
$ServiceName = 'ContosoAgent'
$Port = 9443
$TimeoutSec = 90
$LogPath = "C:\Logs\install-contosoagent-2026-01-27.log"
$RuleName = 'ContosoAgent Inbound'


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
