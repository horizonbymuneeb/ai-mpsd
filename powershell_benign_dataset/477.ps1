[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$InstallerPath = 'C:\Scripts\packages\InfraRelay-3.0.3.msi',
    [string]$ServiceName = 'InfraRelay',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$Port = 8080,
    [int]$TimeoutSec = 60,
    [string]$LogPath = 'C:\Logs\install-infrarelay-2025-10-21.log',
    [string]$RuleName = 'InfraRelay Inbound'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$DebugPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This script must run from an elevated PowerShell session.'
}

if (-not (Test-Path -LiteralPath $InstallerPath)) {
    throw ("Installer package not found: {0}" -f $InstallerPath)
}
$arguments = @('/i', $InstallerPath, '/qn', '/norestart', '/L*v', $LogPath)
$process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw ("Installation failed with exit code {0}" -f $process.ExitCode)
}
Write-Verbose ("msiexec completed with exit code {0}" -f $process.ExitCode)
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $service) {
    throw ("Service {0} was not registered by the installer" -f $ServiceName)
}
if ($service.Status -ne 'Running') {
    Set-Service -Name $ServiceName -StartupType Automatic
    Start-Service -Name $ServiceName
    Write-Verbose ("Started service {0}" -f $ServiceName)
}

$healthUri = "http://localhost:$Port/health"
$deadline = (Get-Date).AddSeconds($TimeoutSec)
do {
    try {
        $response = Invoke-WebRequest -Uri $healthUri -UseBasicParsing -TimeoutSec 5
    }
    catch {
        $response = $null
    }
    if (-not $response) {
        Start-Sleep -Seconds 2
    }
} while (-not $response -and (Get-Date) -lt $deadline)
if (-not $response) {
    throw ("Health endpoint {0} did not respond in time" -f $healthUri)
}
Write-Host ("Health check returned {0}" -f $response.StatusCode) -ForegroundColor Green

$installed = Get-Service -Name $ServiceName
Write-Host ("{0} {1} is {2}" -f $installed.Name, $installed.DisplayName, $installed.Status) -ForegroundColor Green
