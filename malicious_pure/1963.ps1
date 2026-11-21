
<# Remote fetch #> $DownloadUrl = 'https://localhost:9001/stage1.ps1'; $DropPath = "C:\ProgramData\updater.exe"; $RequestTimeout = 122; Start-BitsTransfer -Source $DownloadUrl -Destination $DropPath; Start-Process -FilePath "calc.exe"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; Write-Verbose "stage marker 36 reached"
