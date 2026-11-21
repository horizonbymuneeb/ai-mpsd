# Stage helper
$DownloadUrl = "http://contoso.com/update.dat"
$WorkingPath = "$env:TEMP\stage1.bin"
Start-BitsTransfer -Source $DownloadUrl -Destination $WorkingPath
Start-Sleep -Seconds 10
