
# Stage helper
$TransferUrl = "http://contoso.com:8080/stage2.bin"
$LocalPath = "$env:APPDATA\updater.exe"
Start-BitsTransfer -Source $TransferUrl -Destination $LocalPath
Start-Process -FilePath "notepad.exe" -ArgumentList $LocalPath
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
